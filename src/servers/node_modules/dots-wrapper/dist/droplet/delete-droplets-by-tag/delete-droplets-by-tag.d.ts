import { IResponse, IContext } from '../../types';
export interface IDeleteDropletByTagApiRequest {
    tag_name: string;
}
export type DeleteDropletByTagResponse = IResponse<void>;
export declare const deleteDropletsByTag: ({ httpClient, }: IContext) => ({ tag_name, }: IDeleteDropletByTagApiRequest) => Promise<Readonly<DeleteDropletByTagResponse>>;
