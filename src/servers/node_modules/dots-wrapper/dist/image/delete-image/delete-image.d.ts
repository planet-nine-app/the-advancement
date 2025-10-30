import { IResponse, IContext } from '../../types';
export interface IDeleteImageApiRequest {
    image_id: number;
}
export type DeleteImageRes = IResponse<void>;
export declare const deleteImage: ({ httpClient, }: IContext) => ({ image_id, }: IDeleteImageApiRequest) => Promise<Readonly<DeleteImageRes>>;
