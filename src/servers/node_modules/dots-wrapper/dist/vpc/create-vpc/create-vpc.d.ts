import { IResponse, IContext } from '../../types';
import { IVpc } from '../';
export interface ICreateVpcApiResponse {
    vpc: IVpc;
}
export interface ICreateVpcApiRequest {
    description?: string;
    ip_range?: string;
    is_default?: boolean;
    name: string;
    region: string;
}
export type CreateVpcResponse = IResponse<ICreateVpcApiResponse>;
export declare const createVpc: ({ httpClient, }: IContext) => ({ description, ip_range, is_default, name, region, }: ICreateVpcApiRequest) => Promise<Readonly<CreateVpcResponse>>;
