"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAction = void 0;
const getAction = ({ httpClient, }) => ({ action_id, }) => {
    const url = `/actions/${action_id}`;
    return httpClient.get(url);
};
exports.getAction = getAction;
//# sourceMappingURL=get-action.js.map