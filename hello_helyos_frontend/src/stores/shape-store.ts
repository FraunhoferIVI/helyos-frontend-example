import { defineStore } from 'pinia'
import { ref } from 'vue'
import type { H_Shape } from 'helyosjs-sdk'
import { pushNewShape, deleteShape } from '@/services/helyos-service'


export const useShapeStore = defineStore('shape', () => {
    // Initiate helyos shape store
    const shapes = ref([] as H_Shape[]); // all of helyOS shape objects

    // get shapes of selected yard from shape store
    const filterShapeByYard = (yardId: string) => {
        return shapes.value.filter((shape) => {
            return shape.yardId === yardId;
        })
    }

    // push new shape 
    const pushShape = async (shape: any) => {
        // push new shape into helyos database
        const newShape = await pushNewShape(shape);
        console.log(newShape);

        // push new shape into shape store
        if (newShape) {
            shapes.value.push(newShape as H_Shape);
            alert("Push successfully!");
        } else {
            alert("Push failed!")
        }
    }

    // delete all shapes of selected yard
    const deleteShapesByYard = (yardId: string) => {
        // shapes to be deleted
        const deleteGroup = filterShapeByYard(yardId);
        console.log(deleteGroup);

        if (deleteGroup.length) {
            deleteGroup.forEach((shape) => {
                // delete shape from helyos database
                deleteShape(shape.id);

                // delete shape from shape store
                const index = shapes.value.indexOf(shape);
                if (index > -1) {
                    shapes.value.splice(index, 1);
                }
            })
            alert("Delete" + deleteGroup.length + " shape(s) successfully!")
        }
        else {
            alert("Nothing to be deleted!")
        }

    }

    return {
        shapes,
        filterShapeByYard,
        pushShape,
        deleteShapesByYard,
    }

})