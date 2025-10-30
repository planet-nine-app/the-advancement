import { IResponse, IContext, IListResponse, IListRequest } from '../../types';
import { IImage } from '..';
export interface IListImageApiResponse extends IListResponse {
    images: IImage[];
}
export type IImageType = 'distribution' | 'application' | undefined;
export interface IListImageApiRequest extends IListRequest {
    type?: IImageType;
    user_images?: boolean;
    tag_name?: string;
}
export type ListImagesResponse = IResponse<IListImageApiResponse>;
export declare const listImages: ({ httpClient, }: IContext) => ({ page, per_page, tag_name, type, user_images, }: IListImageApiRequest) => Promise<Readonly<ListImagesResponse>>;
