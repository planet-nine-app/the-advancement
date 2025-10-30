import { IResponse, IContext } from '../../types';
import { ITag } from '..';
export interface ICreateTagApiResponse {
    tag: ITag;
}
export interface ICreateTagApiRequest {
    name: string;
}
export type CreateTagResponse = IResponse<ICreateTagApiResponse>;
export declare const createTag: ({ httpClient, }: IContext) => ({ name, }: ICreateTagApiRequest) => Promise<Readonly<CreateTagResponse>>;
