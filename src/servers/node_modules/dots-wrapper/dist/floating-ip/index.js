"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
__exportStar(require("./assign-ip-to-droplet/assign-ip-to-droplet"), exports);
__exportStar(require("./create-floating-ip/create-floating-ip"), exports);
__exportStar(require("./delete-floating-ip/delete-floating-ip"), exports);
__exportStar(require("./get-floating-ip-action/get-floating-ip-action"), exports);
__exportStar(require("./get-floating-ip/get-floating-ip"), exports);
__exportStar(require("./list-floating-ip-actions/list-floating-ip-actions"), exports);
__exportStar(require("./list-floating-ips/list-floating-ips"), exports);
__exportStar(require("./unassign-ip-from-droplet/unassign-ip-from-droplet"), exports);
__exportStar(require("./types"), exports);
//# sourceMappingURL=index.js.map