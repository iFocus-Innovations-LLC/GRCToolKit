/**
 * Multi-LLM BYOK adapter for GRCToolKit Community.
 * Gemini remains the default. OpenAI / Anthropic / Groq / Vertex use browser keys
 * when CORS allows, otherwise the local runner proxy (127.0.0.1:8081).
 *
 * HITL: analysis only — no remediation. Logs provider + modelId for AU-2 metadata.
 */
(function (global) {
    const STORAGE_KEY = "grc_llm_provider";
    const MODEL_STORAGE_KEY = "grc_llm_model";

    const PROVIDERS = {
        gemini: {
            id: "gemini",
            label: "Google Gemini (default)",
            defaultModel: "gemini-2.5-flash",
            keyWindowVar: "GEMINI_API_KEY",
            supportsBrowserDirect: true,
        },
        openai: {
            id: "openai",
            label: "OpenAI",
            defaultModel: "gpt-4o-mini",
            keyWindowVar: "OPENAI_API_KEY",
            supportsBrowserDirect: false,
        },
        anthropic: {
            id: "anthropic",
            label: "Anthropic Claude",
            defaultModel: "claude-sonnet-4-20250514",
            keyWindowVar: "ANTHROPIC_API_KEY",
            supportsBrowserDirect: false,
        },
        groq: {
            id: "groq",
            label: "Groq",
            defaultModel: "llama-3.3-70b-versatile",
            keyWindowVar: "GROQ_API_KEY",
            supportsBrowserDirect: false,
        },
        vertex: {
            id: "vertex",
            label: "Google Vertex AI",
            defaultModel: "gemini-2.5-flash",
            keyWindowVar: "VERTEX_API_KEY",
            supportsBrowserDirect: false,
        },
    };

    function proxyBase() {
        return (global.ANSIBLE_API_BASE || "http://127.0.0.1:8081").replace(/\/$/, "");
    }

    function getProviderId() {
        const fromWindow = (global.LLM_PROVIDER || "").trim().toLowerCase();
        if (fromWindow && PROVIDERS[fromWindow]) return fromWindow;
        try {
            const stored = (localStorage.getItem(STORAGE_KEY) || "").trim().toLowerCase();
            if (stored && PROVIDERS[stored]) return stored;
        } catch {
            /* private mode */
        }
        return "gemini";
    }

    function setProviderId(id) {
        const normalized = (id || "gemini").trim().toLowerCase();
        if (!PROVIDERS[normalized]) {
            throw new Error("Unknown LLM provider: " + id);
        }
        try {
            localStorage.setItem(STORAGE_KEY, normalized);
        } catch {
            /* private mode */
        }
        global.LLM_PROVIDER = normalized;
        return normalized;
    }

    function getModelId(providerId) {
        const p = PROVIDERS[providerId] || PROVIDERS.gemini;
        try {
            const stored = (localStorage.getItem(MODEL_STORAGE_KEY + ":" + p.id) || "").trim();
            if (stored) return stored;
        } catch {
            /* */
        }
        if (p.id === "gemini") {
            return global.GEMINI_MODEL || p.defaultModel;
        }
        if (p.id === "openai") {
            return global.OPENAI_MODEL || p.defaultModel;
        }
        if (p.id === "anthropic") {
            return global.ANTHROPIC_MODEL || p.defaultModel;
        }
        if (p.id === "groq") {
            return global.GROQ_MODEL || p.defaultModel;
        }
        if (p.id === "vertex") {
            return global.VERTEX_MODEL || p.defaultModel;
        }
        return p.defaultModel;
    }

    function setModelId(providerId, modelId) {
        const p = PROVIDERS[providerId] || PROVIDERS.gemini;
        const m = (modelId || "").trim();
        if (!m) return;
        try {
            localStorage.setItem(MODEL_STORAGE_KEY + ":" + p.id, m);
        } catch {
            /* */
        }
    }

    function getApiKey(providerId) {
        const p = PROVIDERS[providerId] || PROVIDERS.gemini;
        const v = global[p.keyWindowVar];
        return typeof v === "string" ? v.trim() : "";
    }

    function listProviders() {
        return Object.values(PROVIDERS).map((p) => ({
            id: p.id,
            label: p.label,
            defaultModel: p.defaultModel,
        }));
    }

    function extractJsonText(text) {
        if (!text || typeof text !== "string") return null;
        const trimmed = text.trim();
        try {
            return JSON.parse(trimmed);
        } catch {
            /* fall through */
        }
        const fence = trimmed.match(/```(?:json)?\s*([\s\S]*?)```/i);
        if (fence) {
            try {
                return JSON.parse(fence[1].trim());
            } catch {
                /* */
            }
        }
        const start = trimmed.indexOf("{");
        const end = trimmed.lastIndexOf("}");
        if (start >= 0 && end > start) {
            try {
                return JSON.parse(trimmed.slice(start, end + 1));
            } catch {
                /* */
            }
        }
        return null;
    }

    async function analyzeViaProxy(providerId, modelId, prompt, apiKey) {
        const res = await fetch(proxyBase() + "/api/llm/analyze", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                provider: providerId,
                model: modelId,
                prompt,
                apiKey: apiKey || undefined,
            }),
        });
        const raw = await res.text();
        let data;
        try {
            data = JSON.parse(raw);
        } catch {
            throw new Error("LLM proxy returned non-JSON (" + res.status + ")");
        }
        if (!res.ok) {
            throw new Error(data.error || "LLM proxy error: " + res.status);
        }
        return {
            text: data.text || "",
            parsedJson: data.parsedJson || extractJsonText(data.text || ""),
            provider: data.provider || providerId,
            modelId: data.modelId || modelId,
            via: "proxy",
        };
    }

    async function analyzeGeminiDirect(modelId, prompt, apiKey) {
        const apiUrl =
            "https://generativelanguage.googleapis.com/v1beta/models/" +
            encodeURIComponent(modelId) +
            ":generateContent?key=" +
            encodeURIComponent(apiKey);

        const genBase = {
            temperature: 0.3,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 8192,
            responseMimeType: "application/json",
        };

        async function call(withMime, maxTokens, disableThinking) {
            const generationConfig = withMime
                ? { ...genBase, maxOutputTokens: maxTokens }
                : {
                      temperature: genBase.temperature,
                      topK: genBase.topK,
                      topP: genBase.topP,
                      maxOutputTokens: maxTokens,
                  };
            if (!disableThinking && /^gemini-2\.5/i.test(modelId)) {
                generationConfig.thinkingConfig = { thinkingBudget: 0 };
            }
            const res = await fetch(apiUrl, {
                method: "POST",
                headers: { "Content-Type": "application/json" },
                body: JSON.stringify({
                    contents: [{ role: "user", parts: [{ text: prompt }] }],
                    generationConfig,
                }),
            });
            const raw = await res.text();
            return { res, raw };
        }

        let usedMime = true;
        let maxTokens = 8192;
        let disableThinking = false;
        let { res, raw } = await call(true, maxTokens, disableThinking);

        if (!res.ok && /thinkingConfig|thinkingBudget/i.test(raw)) {
            disableThinking = true;
            ({ res, raw } = await call(usedMime, maxTokens, disableThinking));
        }
        if (!res.ok && /responseMimeType|Unknown name/i.test(raw)) {
            usedMime = false;
            ({ res, raw } = await call(false, maxTokens, disableThinking));
        }
        if (!res.ok) {
            let msg = raw;
            try {
                msg = JSON.parse(raw).error?.message || raw;
            } catch {
                /* */
            }
            throw new Error("API error: " + res.status + " - " + msg);
        }

        const result = JSON.parse(raw);
        let text = result.candidates?.[0]?.content?.parts?.[0]?.text || "";
        const finishReason = result.candidates?.[0]?.finishReason;
        if (finishReason === "MAX_TOKENS" && maxTokens < 16384) {
            ({ res, raw } = await call(usedMime, 16384, disableThinking));
            if (res.ok) {
                const retry = JSON.parse(raw);
                text = retry.candidates?.[0]?.content?.parts?.[0]?.text || text;
            }
        }

        return {
            text,
            parsedJson: extractJsonText(text),
            provider: "gemini",
            modelId,
            via: "browser",
        };
    }

    /**
     * @param {string} prompt Full system+user prompt expecting JSON GRC controls
     * @returns {Promise<{text:string,parsedJson:object|null,provider:string,modelId:string,via:string}>}
     */
    async function analyzeScenario(prompt) {
        const providerId = getProviderId();
        const modelId = getModelId(providerId);
        const apiKey = getApiKey(providerId);
        const meta = { provider: providerId, modelId, at: new Date().toISOString() };
        console.info("[GRC LLM] analyzeScenario", meta);

        if (providerId === "gemini" && apiKey) {
            try {
                return await analyzeGeminiDirect(modelId, prompt, apiKey);
            } catch (err) {
                console.warn("[GRC LLM] Gemini direct failed; trying local proxy", err);
                return analyzeViaProxy(providerId, modelId, prompt, apiKey);
            }
        }

        if (!apiKey && providerId !== "vertex") {
            const p = PROVIDERS[providerId];
            throw new Error(
                "No API key for " +
                    p.label +
                    ". Set " +
                    p.keyWindowVar +
                    " via .env.local / run-local.sh, or window." +
                    p.keyWindowVar +
                    " in the console. Non-Gemini providers usually need the local proxy (./scripts/run-local.sh)."
            );
        }

        return analyzeViaProxy(providerId, modelId, prompt, apiKey);
    }

    const api = {
        PROVIDERS,
        listProviders,
        getProviderId,
        setProviderId,
        getModelId,
        setModelId,
        getApiKey,
        analyzeScenario,
        extractJsonText,
        proxyBase,
    };

    global.GRCLLM = api;
})(typeof window !== "undefined" ? window : globalThis);
