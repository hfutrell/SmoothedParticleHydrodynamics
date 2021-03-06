//
//  Particle.swift
//  SmoothedParticleHydrodynamics
//
//  Created by Holmes Futrell on 8/25/16.
//  Copyright © 2016 Holmes Futrell. All rights reserved.
//

import Foundation

struct Particle: CellObjectProtocol {
    var x: CGPoint
    var v: CGPoint
    var m: CGFloat
    var f: CGPoint
    init(x: CGPoint, v: CGPoint, m: CGFloat) {
        self.x = x;
        self.v = v;
        self.m = m;
        self.f = CGPoint(x: 0.0, y: 0.0)
    }
    mutating func applyForces(timeDelta: CGFloat) {
        self.v += self.f * timeDelta
        self.f = CGPoint(x: 0.0, y: 0.0)
    }
    mutating func updatePosition(timeDelta: CGFloat) {
        self.x += self.v * timeDelta
    }
}

func leonardJones(x1 x1: CGPoint, x2: CGPoint, k: CGFloat) -> CGPoint {
    
    // computes Leonard Jones forces between two particles
    let k1 = k
    let k2 = k;
    let m: CGFloat = 4
    let n: CGFloat = 2
    
    let diff: CGPoint = x1 - x2
    let length: CGFloat = diff.length
    
    let l1: CGFloat = pow(k1 / length, m)
    let l2: CGFloat = pow(k2 / length, n)
    
    return (l1 - l2) * (diff / length)
    
}

extension CGPoint {
    var length: CGFloat {
        return sqrt(self.lengthSquared)
    }
    var lengthSquared: CGFloat {
        let x = self.x
        let y = self.y
        return x * x + y * y
    }
    func normalize() -> CGPoint {
        return self / self.length
    }
}
func += (inout left: CGPoint, right: CGPoint) {
    return left = left + right
}
func -= (inout left: CGPoint, right: CGPoint) {
    return left = left - right
}
func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}
func / (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x / right, y: left.y / right)
}
func * (left: CGFloat, right: CGPoint) -> CGPoint {
    return CGPoint(x: left * right.x, y: left * right.y)
}
func * (left: CGPoint, right: CGFloat) -> CGPoint {
    return CGPoint(x: left.x * right, y: left.y * right)
}


