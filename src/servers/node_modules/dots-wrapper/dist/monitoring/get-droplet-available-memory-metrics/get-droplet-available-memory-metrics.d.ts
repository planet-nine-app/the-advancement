import { IResponse, IContext } from '../../types';
import { IDefaultMetricsResponse } from '..';
export interface IGetDropletAvailableMemoryMetricsInput {
    end: string | number;
    host_id: string | number;
    start: string | number;
}
export type GetDropletAvailableMemoryMetricsResponse = IResponse<IDefaultMetricsResponse>;
export declare const getDropletAvailableMemoryMetrics: ({ httpClient, }: IContext) => ({ end, host_id, start, }: IGetDropletAvailableMemoryMetricsInput) => Promise<Readonly<GetDropletAvailableMemoryMetricsResponse>>;
