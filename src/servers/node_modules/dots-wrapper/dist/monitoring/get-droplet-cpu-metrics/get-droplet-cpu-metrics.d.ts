import { IResponse, IContext } from '../../types';
import { IDefaultMetricsResponse } from '..';
export interface IGetDropletCpuMetricsInput {
    end: string | number;
    host_id: string | number;
    start: string | number;
}
export type GetDropletCpuMetricsResponse = IResponse<IDefaultMetricsResponse>;
export declare const getDropletCpuMetrics: ({ httpClient, }: IContext) => ({ end, host_id, start, }: IGetDropletCpuMetricsInput) => Promise<Readonly<GetDropletCpuMetricsResponse>>;
