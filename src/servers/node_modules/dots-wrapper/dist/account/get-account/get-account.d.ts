import { IResponse, IContext } from '../../types';
import { IAccount } from '..';
export interface IGetAccountApiResponse {
    account: IAccount;
}
export type GetAccountResponse = IResponse<IGetAccountApiResponse>;
export declare const getAccount: ({ httpClient, }: IContext) => () => Promise<Readonly<GetAccountResponse>>;
