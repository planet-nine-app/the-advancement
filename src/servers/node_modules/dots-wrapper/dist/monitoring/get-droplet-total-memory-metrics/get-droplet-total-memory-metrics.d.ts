import { IResponse, IContext } from '../../types';
import { IDefaultMetricsResponse } from '..';
export interface IGetDropletTotalMemoryMetricsInput {
    end: string | number;
    host_id: string | number;
    start: string | number;
}
export type GetDropletTotalMemoryMetricsResponse = IResponse<IDefaultMetricsResponse>;
export declare const getDropletTotalMemoryMetrics: ({ httpClient, }: IContext) => ({ end, host_id, start, }: IGetDropletTotalMemoryMetricsInput) => Promise<Readonly<GetDropletTotalMemoryMetricsResponse>>;
