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
    var firstIndex: Int
    var objects: UnsafeMutablePointer<ObjectType> = nil
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
    
    func generateObjectsByApplyingSpacialFunction(nextObjects: UnsafeMutablePointer<ObjectType>,
                maxDistance: Double,
                initializeCallback: (index: Int, objects: UnsafeMutablePointer<ObjectType>, referenceObject: ObjectType ) -> Void,
                     applyCallback: (index: Int, objects: UnsafeMutablePointer<ObjectType>, referenceObject: ObjectType, otherObject: ObjectType ) -> Void

        ) {
        
        let cellsToCheck: Int = Int(ceil(maxDistance / self.cellSize))
        
        var objectIndex1 = 0
        
        for i in 0..<self.verticalCells {
            for j in 0..<self.horizontalCells {

                let cell1 = self.cell(atHorizontalIndex: j, verticalIndex: i)
                for m in 0..<cell1.count {
                    let object1 : ObjectType = cell1.objects[m]

                    initializeCallback(index: objectIndex1, objects: nextObjects, referenceObject: object1)
                    
                    let minK = i - cellsToCheck < 0 ? 0 : i - cellsToCheck
                    let maxK = i + cellsToCheck > (self.verticalCells - 1) ? (self.verticalCells - 1) : i + cellsToCheck
                    
                    var objectIndex2 = 0
                    for k in minK ..< maxK {
                        
                        let minL = (j - cellsToCheck) < 0 ? 0 : (j - cellsToCheck)
                        let maxL = (j + cellsToCheck) > (self.horizontalCells - 1) ? (self.horizontalCells - 1) : j + cellsToCheck
                        
                        for l in minL ..< maxL {
                            // alright so we're dealing with block (j, i) against (l, k)
                            let cell2 = self.cell(atHorizontalIndex: l, verticalIndex: k)
                            for n in 0..<cell2.count {
                                let object2 : ObjectType = cell2.objects[n]
                                
                                applyCallback(index1: objectIndex1, index2: objectIndex2, objects: nextObjects, referenceObject: object1, otherObject: object2)
                                
                            }
                            
                        }
                        objectIndex2 += 1
                    }
                    objectIndex1 += 1
                }
                
                
            }
        }
        
        
    }
    
}