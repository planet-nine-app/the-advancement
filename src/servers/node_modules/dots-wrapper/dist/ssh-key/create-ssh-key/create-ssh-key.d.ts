import { IResponse, IContext } from '../../types';
import { ISshKey } from '..';
export interface ICreateSshKeyApiResponse {
    ssh_key: ISshKey;
}
export interface ICreateSshKeyApiRequest {
    name: string;
    public_key: string;
}
export type CreateSshKeyResponse = IResponse<ICreateSshKeyApiResponse>;
export declare const createSshKey: ({ httpClient, }: IContext) => ({ name, public_key, }: ICreateSshKeyApiRequest) => Promise<Readonly<CreateSshKeyResponse>>;
