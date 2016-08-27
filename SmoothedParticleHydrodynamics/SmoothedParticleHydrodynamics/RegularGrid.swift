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
    let numCells: Int
    
    let cellSize: Double
    let cellStride: Int // offset to add per row when indexing into cells
    
    required init(withWidth width: Double, height: Double, cellSize: Double, maxObjects: Int) {
        
        assert(cellSize > 0)
        
        self.width = width
        self.height = height
        self.cellSize = cellSize
        
        let horizontalCells: Int = Int(ceil(width / cellSize))
        let verticalCells: Int = Int(ceil(height / cellSize))
        let numCells = horizontalCells * verticalCells
        self.cellStride = horizontalCells
        
        self.objectData = NSMutableData(length: sizeof(ObjectType) * maxObjects )! // zero-filled per documentation
        self.objects = UnsafeMutablePointer<ObjectType>(objectData.bytes)

        self.numCells = numCells
        self.cellData = NSMutableData(length: sizeof(Cell<ObjectType>) * self.numCells )! // zero-filled per documentation
        self.cells = UnsafeMutablePointer<Cell<ObjectType>>(cellData.bytes)

        self.numObjects = 0
        self.maxObjects = maxObjects
        
    }
    
    func cell(atLocation location: CGPoint) -> Cell<ObjectType> {
       
        assert((Double(location.x) >= 0) && (Double(location.x) <= self.width))
        assert((Double(location.y) >= 0) && (Double(location.y) <= self.height))

        let horizontalIndex: Int = Int(floor(Double(location.x) / cellSize))
        let verticalIndex: Int   = Int(floor(Double(location.y) / cellSize))
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
    
}