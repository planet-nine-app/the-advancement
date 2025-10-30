import { IResponse, IContext } from '../../types';
export interface IDeleteVpcApiRequest {
    vpc_id: string;
}
export type DeleteVpcResponse = IResponse<void>;
export declare const deleteVpc: ({ httpClient, }: IContext) => ({ vpc_id, }: IDeleteVpcApiRequest) => Promise<Readonly<DeleteVpcResponse>>;
