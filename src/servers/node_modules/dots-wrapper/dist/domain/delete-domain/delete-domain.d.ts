import { IResponse, IContext } from '../../types';
export interface IDeleteDomainApiRequest {
    name: string;
}
export type DeleteDomainResponse = IResponse<void>;
export declare const deleteDomain: ({ httpClient, }: IContext) => ({ name, }: IDeleteDomainApiRequest) => Promise<Readonly<DeleteDomainResponse>>;
