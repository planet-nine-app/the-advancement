import { IResponse, IContext } from '../../types';
import { ITagResourcePayload } from '..';
export interface ITagResourcesApiRequest {
    tag_name: string;
    resources: ITagResourcePayload[];
}
export type TagResourcesResponse = IResponse<void>;
export declare const tagResources: ({ httpClient, }: IContext) => ({ tag_name, resources, }: ITagResourcesApiRequest) => Promise<Readonly<TagResourcesResponse>>;
