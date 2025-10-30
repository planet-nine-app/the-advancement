import { AxiosStatic } from 'axios';
import { IContext } from '../../types';
export interface ICreateContextInput {
    axios: AxiosStatic;
    endpoint?: string;
    requestTimeoutInMs?: number;
    token: string;
}
export declare const createContext: ({ axios, requestTimeoutInMs, endpoint, token, }: ICreateContextInput) => Readonly<IContext>;
