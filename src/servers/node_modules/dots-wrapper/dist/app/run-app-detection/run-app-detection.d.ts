import { IResponse, IContext } from '../../types';
import { IGithubSource, IGitSource } from '..';
export interface IRunAppDetectionComponent {
    environment_slug: string;
    run_command: string;
    strategy: string;
    types: string[];
}
export interface IRunAppDetectionApiResponse {
    components: IRunAppDetectionComponent[];
}
export interface IRunAppDetectionApiRequest {
    commit_sha?: string;
    component_type?: string;
    git?: IGitSource;
    github?: IGithubSource;
}
export type RunAppDetectionResponse = IResponse<IRunAppDetectionApiResponse>;
export declare const runAppDetection: ({ httpClient, }: IContext) => ({ commit_sha, component_type, git, github, }: IRunAppDetectionApiRequest) => Promise<Readonly<RunAppDetectionResponse>>;
