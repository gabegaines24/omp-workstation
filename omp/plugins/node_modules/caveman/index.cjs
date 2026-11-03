'use strict';

const STATUS_LABEL = 'caveman';
const STATUS_TEXT = 'CAVEMAN';
const RULE = "Respond terse like smart caveman. All technical substance stay. Only fluff die.\n\nRules:\n- Answer first: Answer, then reason, then next step.\n- Kill ceremony: No greeting, hedging, pleasantries, recap, or closer.\n- Short word: \"fix\" not \"implement a solution for\".\n- Articles optional, meaning never: Drop a/an/the when the sentence still reads in one pass.\n- One idea per sentence: ASD-STE100 is the floor: 20 words max, active voice, imperative for instructions, one term per thing, pronoun only with an obvious referent.\n- Payload verbatim: Code blocks unchanged.\n- Tool runs: bounded status: No text between routine calls.\n- User's language: Compress the style, not the language.\n- Never perform caveman: No \"caveman mode on\", no \"me think\", no \"Caveman:\" prefix, no normal answer plus caveman copy.\n\nSwitch: /caveman (default), /ultracave (fragments, each fact once), /megacave (Classical Chinese 文言文)\nStop: \"stop caveman\" or \"normal mode\"\n\nAuto-Clarity: plain prose for security warnings, irreversible actions, step order a fragment could scramble, user confused. Resume after.\n\nBoundaries: code, comments, commits, PRs, docs written normal.\nFloor: code, commands, paths, numbers and error strings verbatim; never drop not/never/no/only.\n";

module.exports = function cavemanPlugin(pi) {
  if (!pi || typeof pi.on !== 'function') return;
  pi.on('session_start', async (_event, ctx) => {
    if (ctx && ctx.ui && typeof ctx.ui.setStatus === 'function') {
      ctx.ui.setStatus(STATUS_LABEL, STATUS_TEXT);
    }
  });
  pi.on('before_agent_start', async (event) => {
    const base = event && Array.isArray(event.systemPrompt) ? event.systemPrompt : [];
    const entry = 'CAVEMAN MODE ACTIVE - session ruleset applies.' + String.fromCharCode(10, 10) + RULE;
    if (base.indexOf(entry) !== -1) return undefined;
    return { systemPrompt: base.concat([entry]) };
  });
};
