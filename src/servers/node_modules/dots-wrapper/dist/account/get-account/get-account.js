"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getAccount = void 0;
const getAccount = ({ httpClient, }) => () => {
    const path = '/account';
    const url = `${path}`;
    return httpClient.get(url);
};
exports.getAccount = getAccount;
//# sourceMappingURL=get-account.js.map