import { IResponse, IContext } from '../../types';
import { IBalance } from '../';
export type GetBalanceResponse = IResponse<IBalance>;
export declare const getBalance: ({ httpClient, }: IContext) => () => Promise<Readonly<GetBalanceResponse>>;
