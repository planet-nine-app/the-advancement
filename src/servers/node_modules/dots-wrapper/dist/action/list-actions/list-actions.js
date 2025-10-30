"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.listActions = void 0;
const listActions = ({ httpClient, }) => ({ page = 1, per_page = 25, }) => {
    const path = '/actions';
    const query_params = { page, per_page };
    const url = `${path}`;
    return httpClient.get(url, { params: query_params });
};
exports.listActions = listActions;
//# sourceMappingURL=list-actions.js.map