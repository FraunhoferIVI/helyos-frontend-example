import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { H_MapObject } from 'helyosjs-sdk'
import { pushNewMapObject, deleteMapObject } from '@/services/helyos-service'


export const useMapObjectStore = defineStore('map-object', () => {
    // Initiate helyos map objects store
    const mapObjects = ref([] as H_MapObject[]); // all of helyOS map object

    // get map objects of selected yard from map object store
    const filterMapObjectByYard = (yardId: string) => {
        return mapObjects.value.filter((mapObject) => {
            return mapObject.yardId === yardId;
        })
    }

    // push new MapObject 
    const pushMapObject = async (mapObject: any) => {
        // push new MapObject into helyos database
        const newMapObject = await pushNewMapObject(mapObject);
        console.log(newMapObject);

        // push new MapObject into MapObject store
        if (newMapObject) {
            mapObjects.value.push(newMapObject);
            alert("Push successfully!");
        } else {
            alert("Push failed!")
        }
    }

    // delete all MapObjects of selected yard
    const deleteMapObjectsByYard = (yardId: string) => {
        // MapObjects to be deleted
        const deleteGroup = filterMapObjectByYard(yardId);
        console.log(deleteGroup);

        if (deleteGroup.length) {
            deleteGroup.forEach((mapObject) => {
                // delete MapObject from helyos database
                deleteMapObject(mapObject.id);

                // delete MapObject from MapObject store
                const index = mapObjects.value.indexOf(mapObject);
                if (index > -1) {
                    mapObjects.value.splice(index, 1);
                }
            })
            alert("Delete" + deleteGroup.length + " MapObject(s) successfully!")
        }
        else {
            alert("Nothing to be deleted!")
        }

    }

    return {
        mapObjects,
        filterMapObjectByYard,
        pushMapObject,
        deleteMapObjectsByYard,
    }

})