import { IResponse, IContext } from '../../types';
import { IDefaultMetricsResponse } from '..';
export interface IGetDropletFreeMemoryMetricsInput {
    end: string | number;
    host_id: string | number;
    start: string | number;
}
export type GetDropletFreeMemoryMetricsResponse = IResponse<IDefaultMetricsResponse>;
export declare const getDropletFreeMemoryMetrics: ({ httpClient, }: IContext) => ({ end, host_id, start, }: IGetDropletFreeMemoryMetricsInput) => Promise<Readonly<GetDropletFreeMemoryMetricsResponse>>;
