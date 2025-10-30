import { IResponse, IContext } from '../../types';
import { IImage } from '..';
export interface IGetImageApiRequest {
    image_id?: number;
    slug?: string;
}
export interface IGetImageApiResponse {
    image: IImage;
}
export type GetImageResponse = IResponse<IGetImageApiResponse>;
export declare const getImage: ({ httpClient, }: IContext) => ({ image_id, slug, }: IGetImageApiRequest) => Promise<Readonly<GetImageResponse>>;
