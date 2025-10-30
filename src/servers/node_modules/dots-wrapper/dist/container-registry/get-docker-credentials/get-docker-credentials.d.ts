import { IResponse, IContext } from '../../types';
export interface IGetDockerCredentialsApiRequest {
    can_write?: boolean;
    expiry_seconds?: number;
}
export interface IGetDockerCredentialsApiResponse {
    [key: string]: any;
}
export type GetDockerCredentialsResponse = IResponse<IGetDockerCredentialsApiResponse>;
export declare const getDockerCredentials: ({ httpClient, }: IContext) => ({ can_write, expiry_seconds, }: IGetDockerCredentialsApiRequest) => Promise<Readonly<GetDockerCredentialsResponse>>;
