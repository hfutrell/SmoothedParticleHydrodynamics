//
//  RegularGrid.swift
//  SmoothedParticleHydrodynamics
//
//  Created by Holmes Futrell on 8/26/16.
//  Copyright © 2016 Holmes Futrell. All rights reserved.
//

import Foundation

protocol CellObjectProtocol {
    var x: CGPoint { get }
}

internal class Cell<ObjectType> {
    var count: Int = 0
    var firstIndex: Int = 0
    var objects: UnsafeMutablePointer<ObjectType> = nil // todo: remove, it's not strictly necessary to have this pointer
    func insert(object: ObjectType) {
        objects[count] = object
        count += 1
    }
}

class RegularGrid<ObjectType: CellObjectProtocol>  {
    
    let width: Double
    let height: Double
    
    let objects: UnsafeMutablePointer<ObjectType>
    let objectData: NSData
    var numObjects: Int
    let maxObjects: Int

    let cells: UnsafeMutablePointer<Cell<ObjectType>>
    let cellData: NSData
    let horizontalCells: Int
    let verticalCells: Int
    var numCells: Int {
        return horizontalCells * verticalCells
    }
    
    let cellSize: Double
    let cellStride: Int // offset to add per row when indexing into cells
    
    required init(withWidth width: Double, height: Double, cellSize: Double, maxObjects: Int) {
        
        assert(cellSize > 0)
        
        self.width = width
        self.height = height
        self.cellSize = cellSize
        
        self.horizontalCells = Int(ceil(width / cellSize))
        self.verticalCells = Int(ceil(height / cellSize))
        let numCells = self.horizontalCells * self.verticalCells
        self.cellStride = self.horizontalCells
        
        self.objectData = NSMutableData(length: sizeof(ObjectType) * maxObjects )! // zero-filled per documentation
        self.objects = UnsafeMutablePointer<ObjectType>(objectData.bytes)

        self.cellData = NSMutableData(length: sizeof(Cell<ObjectType>) * numCells )! // zero-filled per documentation
        self.cells = UnsafeMutablePointer<Cell<ObjectType>>(cellData.bytes)

        self.numObjects = 0
        self.maxObjects = maxObjects
        
    }
    
    func cell(atLocation location: CGPoint) -> Cell<ObjectType> {
       
        assert((Double(location.x) >= 0) && (Double(location.x) <= self.width))
        assert((Double(location.y) >= 0) && (Double(location.y) <= self.height))

        let horizontalIndex: Int = Int(floor(Double(location.x) / cellSize))
        let verticalIndex: Int   = Int(floor(Double(location.y) / cellSize))
        
        return self.cell(atHorizontalIndex: horizontalIndex, verticalIndex: verticalIndex)
        
    }
    
    func cell(atHorizontalIndex horizontalIndex: Int, verticalIndex: Int) -> Cell<ObjectType> {
        assert(horizontalIndex > 0 && horizontalIndex < self.horizontalCells)
        assert(verticalIndex > 0 && verticalIndex < self.verticalCells)
        let index = verticalIndex * self.cellStride + horizontalIndex
        return self.cells[index]
    }
    
    func setObjects(objects: [ObjectType]) {
        assert(objects.count < self.maxObjects)
        // step 1: update counts for all cells
        for object in objects {
            let cell = self.cell(atLocation: object.x)
            cell.count += 1
        }
        // step 2: use counts to allocate memory for cells and reset counts
        var numObjectsSoFar: Int = 0
        for i in 0..<self.numCells {
            cells[i].objects = self.objects + numObjectsSoFar // pointer arithmetic
            cells[i].firstIndex = numObjectsSoFar
            numObjectsSoFar += cells[i].count
            cells[i].count = 0 // we have to reset this because cell.insert uses it to determine what index to use when inserting
        }
        // step 3: insert objects
        for object in objects {
            let cell = self.cell(atLocation: object.x)
            cell.insert(object)
        }
        // step 4: update object count
        self.numObjects = numObjectsSoFar
    }
    
    // todo: copy object list function 
    
    func generateObjectsByApplyingSpacialFunction(nextObjects: UnsafeMutablePointer<ObjectType>,
                maxDistance: Double,
                applyCallback: (index1: Int, index2: Int, objects: UnsafeMutablePointer<ObjectType>, referenceObject: ObjectType, otherObject: ObjectType ) -> Void

        ) {
        
        let cellsToCheck: Int = Int(ceil(maxDistance / self.cellSize))
        
        for objectIndex1 in 0..<self.numObjects {

            let object1: ObjectType = self.objects[objectIndex1]
            let horizontalCellIndex: Int = Int(floor(Double(object1.x.x) / cellSize))
            let verticalCellIndex: Int   = Int(floor(Double(object1.x.y) / cellSize))

            // check the cells above (and equal row)
            // these have object indices that are less than or equal to object1 cell's object indices
            // when we compare the two objects may actually be in the same cell
            // in this case we take care to ensure that object2's index is less than object1's

            let minK = (verticalCellIndex - cellsToCheck) < 0 ? 0 : (verticalCellIndex - cellsToCheck)
            let maxK = verticalCellIndex
            
            for k in minK ... maxK {
                
                let minL = (horizontalCellIndex - cellsToCheck) < 0 ? 0 : (horizontalCellIndex - cellsToCheck)
                let maxL = (horizontalCellIndex + cellsToCheck) >= self.horizontalCells ? (self.horizontalCells - 1) : (horizontalCellIndex + cellsToCheck)
                
                let firstCell = self.cell(atHorizontalIndex: minL, verticalIndex: k)
                let lastCell = self.cell(atHorizontalIndex: maxL, verticalIndex: k)
                
                for objectIndex2 in firstCell.firstIndex..<(lastCell.firstIndex+lastCell.count) {
                    if ( objectIndex2 < objectIndex1 ) {
                        let object2 : ObjectType = self.objects[objectIndex2]
                        applyCallback(index1: objectIndex1, index2: objectIndex2, objects: nextObjects, referenceObject: object1, otherObject: object2)
                    }
                } // end object2 iteration
            } // end k
        } // end objectIndex1
    }
    
}