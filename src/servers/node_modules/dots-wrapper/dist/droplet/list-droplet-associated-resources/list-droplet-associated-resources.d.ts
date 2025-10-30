import { IResponse, IContext } from '../../types';
export interface IDropletAssociatedResource {
    id: string;
    name: string;
    cost: string;
}
export interface IListDropletAssociatedResourcesApiResponse {
    snapshots: IDropletAssociatedResource[];
    volumes: IDropletAssociatedResource[];
    volume_snapshots: IDropletAssociatedResource[];
}
export interface IListDropletAssociatedResourcesApiRequest {
    droplet_id: number;
}
export type ListDropletAssociatedResourcesResponse = IResponse<IListDropletAssociatedResourcesApiResponse>;
export declare const listDropletAssociatedResources: ({ httpClient, }: IContext) => ({ droplet_id, }: IListDropletAssociatedResourcesApiRequest) => Promise<Readonly<ListDropletAssociatedResourcesResponse>>;
