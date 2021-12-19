import React, { useEffect, useState } from 'react';
import tw, { TwStyle } from 'twin.macro';
import { faCircle, faEthernet, faHdd, faMemory, faMicrochip, faServer, faHeadset, faSitemap, faDatabase, faArchive } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';
import { bytesToHuman, megabytesToHuman, formatIp } from '@/helpers';;
import TitledGreyBox from '@/components/elements/TitledGreyBox';
import { ServerContext } from '@/state/server';
import CopyOnClick from '@/components/elements/CopyOnClick';
import { SocketEvent, SocketRequest } from '@/components/server/events';
import { useDeepMemoize } from '@/plugins/useDeepMemoize';
import useFlash from '@/plugins/useFlash';
import Spinner from '@/components/elements/Spinner';
import UptimeDuration from '@/components/server/UptimeDuration';
import getServerDatabases from '@/api/server/databases/getServerDatabases';
import { httpErrorToHuman } from '@/api/http';
import getServerBackups from '@/api/swr/getServerBackups';

interface Stats {
    memory: number;
    cpu: number;
    disk: number;
    uptime: number;
}

function statusToColor (status: string|null, installing: boolean): TwStyle {
    if (installing) {
        status = '';
    }

    switch (status) {
        case 'offline':
            return tw`text-red-500`;
        case 'running':
            return tw`text-green-500`;
        default:
            return tw`text-yellow-500`;
    }
}

const ServerDetailsBlock = () => {
    const [ stats, setStats ] = useState<Stats>({ memory: 0, cpu: 0, disk: 0, uptime: 0 });

    const status = ServerContext.useStoreState(state => state.status.value);
    const connected = ServerContext.useStoreState(state => state.socket.connected);
    const instance = ServerContext.useStoreState(state => state.socket.instance);

    const statsListener = (data: string) => {
        let stats: any = {};
        try {
            stats = JSON.parse(data);
        } catch (e) {
            return;
        }

        setStats({
            memory: stats.memory_bytes,
            cpu: stats.cpu_absolute,
            disk: stats.disk_bytes,
            uptime: stats.uptime || 0,
        });
    };

    useEffect(() => {
        if (!connected || !instance) {
            return;
        }

        instance.addListener(SocketEvent.STATS, statsListener);
        instance.send(SocketRequest.SEND_STATS);

        return () => {
            instance.removeListener(SocketEvent.STATS, statsListener);
        };
    }, [ instance, connected ]);

    const name = ServerContext.useStoreState(state => state.server.data!.name);
    const isInstalling = ServerContext.useStoreState(state => state.server.data!.isInstalling);
    const isTransferring = ServerContext.useStoreState(state => state.server.data!.isTransferring);
    const limits = ServerContext.useStoreState(state => state.server.data!.limits);
    const primaryAllocation = ServerContext.useStoreState(state => state.server.data!.allocations.filter(alloc => alloc.isDefault).map(
        allocation => (allocation.alias || formatIp(allocation.ip)) + ':' + allocation.port,
    )).toString();
    const id = ServerContext.useStoreState(state => state.server.data!.id);
    const node = ServerContext.useStoreState(state => state.server.data!.node);
    const uuid = ServerContext.useStoreState(state => state.server.data!.uuid);
    const databases = useDeepMemoize(ServerContext.useStoreState(state => state.databases.data));
    const { data: backups, error, isValidating } = getServerBackups();
    const diskLimit = limits.disk ? megabytesToHuman(limits.disk) : 'Unlimited';
    const memoryLimit = limits.memory ? megabytesToHuman(limits.memory) : 'Unlimited';
    const cpuLimit = limits.cpu !== 0 ? limits.cpu + '%' : 'Unlimited';
    const databaseLimit = ServerContext.useStoreState(state => state.server.data!.featureLimits.databases);
    const backupLimit = ServerContext.useStoreState(state => state.server.data!.featureLimits.backups);
    const { addError, clearFlashes, clearAndAddHttpError } = useFlash();
    const [ loading, setLoading ] = useState(true);
    const setDatabases = ServerContext.useStoreActions(state => state.databases.setDatabases);
    //only works in pterodactyl last ver//

    useEffect(() => {
        setLoading(!databases.length);
        clearFlashes('databases');

        getServerDatabases(uuid)
            .then(databases => setDatabases(databases))
            .catch(error => {
                console.error(error);
                addError({ key: 'databases', message: httpErrorToHuman(error) });
            })
            .then(() => setLoading(false));
    }, []);

    useEffect(() => {
        if (!error) {
            clearFlashes('backups');

            return;
        }

        clearAndAddHttpError({ error, key: 'backups' });
    }, [ error ]);

    if (!backups || (error && isValidating)) {
        return <Spinner size={'large'} centered/>;
    }

    return (
        <TitledGreyBox css={tw`break-words`} title={name} icon={faServer}>
            <p css={tw`text-xs uppercase`}>
                <FontAwesomeIcon
                    icon={faCircle}
                    fixedWidth
                    css={[
                        tw`mr-1`,
                        statusToColor(status, isInstalling || isTransferring),
                    ]}
                />
                &nbsp;{!status ? 'Connecting...' : (isInstalling ? 'Installing' : (isTransferring) ? 'Transferring' : status)}
                {stats.uptime > 0 &&
                <span css={tw`ml-2 lowercase`}>
                    (<UptimeDuration uptime={stats.uptime / 1000}/>)
                </span>
                }
            </p>
            <CopyOnClick text={primaryAllocation}>
                <p css={tw`text-xs mt-2`}>
                    <FontAwesomeIcon icon={faEthernet} fixedWidth css={tw`mr-1`}/>
                    <code css={tw`ml-1`}>IP: {primaryAllocation}</code>
                </p>
            </CopyOnClick>
            <CopyOnClick text={id}>
                <p css={tw`text-xs mt-2`}>
                    <FontAwesomeIcon icon={faHeadset} fixedWidth css={tw`mr-1`}/>
                    <code css={tw`ml-1`}>Support code: {id}</code>
                </p>
            </CopyOnClick>
            <p css={tw`text-xs mt-2`}>
                <FontAwesomeIcon icon={faSitemap} fixedWidth css={tw`mr-1`}/> Node: {node}
            </p>
            <p css={tw`text-xs mt-2`}>
                <FontAwesomeIcon icon={faMicrochip} fixedWidth css={tw`mr-1`}/> CPU: {stats.cpu.toFixed(2)}%
                <span css={tw`text-neutral-500`}> / {cpuLimit}</span>
            </p>
            <p css={tw`text-xs mt-2`}>
                <FontAwesomeIcon icon={faMemory} fixedWidth css={tw`mr-1`}/> Memory: {bytesToHuman(stats.memory)}
                <span css={tw`text-neutral-500`}> / {memoryLimit}</span>
            </p>
            <p css={tw`text-xs mt-2`}>
                <FontAwesomeIcon icon={faHdd} fixedWidth css={tw`mr-1`}/> Disk: {bytesToHuman(stats.disk)}
                <span css={tw`text-neutral-500`}> / {diskLimit}</span>
            </p>
            <p css={tw`text-xs mt-2`}>
                <FontAwesomeIcon icon={faDatabase} fixedWidth css={tw`mr-1`}/> Databases: {databases.length} used
                <span css={tw`text-neutral-500`}> / {databaseLimit} max</span>
            </p>
            <p css={tw`text-xs mt-2`}>
                <FontAwesomeIcon icon={faArchive} fixedWidth css={tw`mr-1`}/> Backups: {backups.pagination.total} used
                <span css={tw`text-neutral-500`}> / {backupLimit} max</span>
            </p>
        </TitledGreyBox>
    );
};

export default ServerDetailsBlock;