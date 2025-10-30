import { IResponse, IContext } from '../../types';
import { ITagResourcePayload } from '..';
export interface IUntagResourcesApiRequest {
    tag_name: string;
    resources: ITagResourcePayload[];
}
export type UntagResourcesResponse = IResponse<void>;
export declare const untagResources: ({ httpClient, }: IContext) => ({ tag_name, resources, }: IUntagResourcesApiRequest) => Promise<Readonly<UntagResourcesResponse>>;
