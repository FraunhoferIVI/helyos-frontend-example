import { HelyosServices, H_MapObject, H_Tools, H_WorkProcess } from 'helyosjs-sdk';
import { useUserStore } from '@/stores/user-store';
import { useYardStore } from '@/stores/yard-store'
import { useToolStore } from '@/stores/tool-store';
import { useMapObjectStore } from '@/stores/map-object-store';
import { useWorkProcessStore } from '@/stores/work-process-store';


export const helyosService = new HelyosServices('http://localhost', { socketPort: '5002', gqlPort: '5000' });

export const helyosLogin = (username: string, password: string) => {
    if (username && password) {
        return helyosService.login(username, password)
            .then(response => {
                return response
            })
    }
}

// build Websocket connection
export const helyosConnect = () => {

    // check if account's login token correct
    // console.log("hst", helyosService.token);
    const userStore = useUserStore();
    console.log("userStore", userStore.user);

    if (userStore.user.token === helyosService.token) {
        return helyosService.connect()
            .then(connected => {

                // setup helyOS after connection
                helyosSetup();

                return connected;
            })
    }
}

// helyOS setup after connected
const helyosSetup = () => {
    listYards(); // fetch yards from helyos
    listMapObjects(); // fetch mapObjects from helyos
    listTools(); // fetch tools from helyos
    toolSubscription(); // agents listener
    listWorkProcessType(); // fetch work process type from helyos
}


////////////////////////////Yards////////////////////////////
// fetch yards from helyos
const listYards = async () => {
    const yardStore = useYardStore();
    const yards = await helyosService.yard.list({});
    yardStore.yards = yards;
    console.log("yards", yards);
}

////////////////////////////mapObjects////////////////////////////
// fetch mapObjects from helyos
export const listMapObjects = async () => {
    const mapObjectStore = useMapObjectStore();
    const mapObjects = await helyosService.mapObjects.list({});
    mapObjectStore.mapObjects = mapObjects;
    console.log("mapObjects", mapObjects);
}

// fetch mapObjects from helyos by yard id
const listMapObjectsByYardId = async (yardId: string) => {
    const mapObjectStore = useMapObjectStore();
    const mapObjects = await helyosService.mapObjects.list({ yardId: yardId });
    mapObjectStore.mapObjects = mapObjects;
    console.log(mapObjectStore.mapObjects);
}

// create a new helyos mapObject
export const pushNewMapObject = async (mapObject: H_MapObject) => {
    try {
        const newMapObject = await helyosService.mapObjects.create(mapObject)
        console.log("Push mapObject operation succeed!", newMapObject);
        listMapObjects();
        return newMapObject;
    }
    catch {
        console.log("Push mapObject operation failed!");
    }
}

// delete mapObject by id
export const deleteMapObject = async (mapObjectId: any) => {
    try {
        const deletedMapObject = await helyosService.mapObjects.delete(mapObjectId);
        console.log("Delete mapObject operation succeed!", deletedMapObject);
        listMapObjects();
    }
    catch {
        console.log("Delete mapObject operation failed!");
    }
}

////////////////////////////Tools////////////////////////////
// fetch tools from helyos
export const listTools = async () => {
    const toolStore = useToolStore();
    const tools = await helyosService.tools.list({})
    toolStore.tools = tools;
    console.log("tools", tools);
    return tools
}

// modify a tool
export const patchTool = (tool: H_Tools) => {
    try {
        const newTool = helyosService.tools.patch(tool);
        console.log("Patch tool operation succeed!", newTool);
        return newTool;
    }
    catch {
        console.log("Patch tool operation failed!");
    }
}

// agents listener
const toolSubscription = () => {
    const socket = helyosService.socket;
    const toolStore = useToolStore();

    socket.on('new_tool_poses', (updates: any) => {
        // console.log('new_tool_poses', updates); // Notifications from tool sensors.

        // update poses into toolStore
        updates.forEach((agentUpdate: any) => {
            // console.log(agentUpdate);
            const agent = toolStore.tools.find(tool => tool.id === agentUpdate.toolId);
            if (agent) {
                toolStore.ifSubscription = 1;
                agent.x = agentUpdate.x;
                agent.y = agentUpdate.y;
                agent.orientation = agentUpdate.orientation;
                agent.orientations = agentUpdate.orientations;
                agent.sensors = agentUpdate.sensors;
            }
        })
        // console.log("tool store", toolStore.tools);

    });
    socket.on('change_tool_status', (updates: any) => {
        console.log('change_tool_status', updates); // Notifications from tools working status.

        // update status into toolStore
        updates.forEach((agentUpdate: any) => {
            console.log(agentUpdate);
            const agent = toolStore.tools.find(tool => tool.id === agentUpdate.id.toString());
            if (agent) {
                agent.status = agentUpdate.status;
            }
        })
        // console.log("tool store", toolStore.tools);
    });
    socket.on('change_work_processes', (updates: any) => {
        console.log('change_work_processes', updates);  // Notifications from work processes status.
    });
}

////////////////////////////WorkProcess////////////////////////////
// fetch work process type from helyos
const listWorkProcessType = async () => {
    const workProcessStore = useWorkProcessStore();
    const workProcessType = await helyosService.workProcessType.list({});
    workProcessStore.workProcessType = workProcessType;    
}

export const dispatchWorkProcess = async (workProcess: any) => {
    console.log(workProcess);
    return await helyosService.workProcess.create(workProcess)
}

