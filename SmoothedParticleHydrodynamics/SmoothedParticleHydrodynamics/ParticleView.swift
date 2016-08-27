//
//  ParticleView.swift
//  SmoothedParticleHydrodynamics
//
//  Created by Holmes Futrell on 8/25/16.
//  Copyright © 2016 Holmes Futrell. All rights reserved.
//

import Cocoa

class ParticleView : NSView {
    
    var particles: UnsafeMutablePointer<Particle>!
    var particlesData: NSData!
    var numParticles: Int = 0
    
    var renderTimer: NSTimer!
    
    var grid: RegularGrid<Particle>!
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        srand(36758765)
        self.renderTimer = NSTimer.scheduledTimerWithTimeInterval(0,
                                                                  target: self,
                                                                  selector: #selector(ParticleView.renderTimerFired(withTimer:)),
                                                                  userInfo: nil,
                                                                  repeats: true)
        
        self.wantsLayer = false;
//        self.layer!.drawsAsynchronously = true;
        
        let maxObjects = 1000000
        
        self.numParticles = 0
        self.particlesData = NSMutableData(length: sizeof(Particle) * maxObjects)
        self.particles = UnsafeMutablePointer<Particle>(self.particlesData.bytes)
        
        let width: Double = Double(self.bounds.size.width)
        let height: Double = Double(self.bounds.size.height)
        grid = RegularGrid<Particle>(withWidth: width, height: height, cellSize: 4, maxObjects: 1000000)

        NSLog("particle view init")
    }
    
    func swapBuffers<Type>(inout buff1: Type, inout buff2: Type) {
        let temp = buff1
        buff1 = buff2
        buff2 = temp
    }
    
    func randomVector() -> CGPoint {
        
        var vector: CGPoint = CGPointZero
        repeat {
            vector.x = 2.0 * CGFloat( Double(rand()) / Double(RAND_MAX)) - 1.0
            vector.y = 2.0 * CGFloat( Double(rand()) / Double(RAND_MAX)) - 1.0
        } while(vector.length > 1)
        return vector
    }
    
    func renderTimerFired(withTimer timer: NSTimer) {
        
//        NSLog("render timer, num particles = %d", particles.count)
        
        let timeDelta: CGFloat = 1.0 / 60.0
        
        func shouldLive(particle: Particle) -> Bool {
            if particle.x.x < 0 || Double(particle.x.x) > self.grid.width {
                return false
            }
            if particle.x.y < 0 || Double(particle.x.y) > self.grid.height {
                return false
            }
            return true
        }
        
        // generate new particles
//        if rand() % 5 == 1 {
        
            for i in 0..<2 {
                let initialPosition: CGPoint = CGPoint(x: 32, y: 48) + randomVector() * 10.0
                let initialVelocity: CGPoint = CGPoint(x: 32, y: 0) + randomVector() * 1.0
                particles[self.numParticles] = Particle(x: initialPosition, v: initialVelocity, m: 1.0)
                self.numParticles += 1
            }

            
//        }
        
        
        // remove dead particles, compacting the array so that only live ones remain
        var updatedNumAlive = 0
        for i in 0..<self.numParticles {
            var particle: Particle = particles[i]
            if shouldLive(particle) {
                self.particles[updatedNumAlive] = particle
                updatedNumAlive += 1
            }
        }
        self.numParticles = updatedNumAlive

        
        // shove particles in grid and update particle ordering to match grid ordering
        self.grid.setObjects(self.particles, count: self.numParticles)
        self.grid.runFunction({(index: Int, particle: Particle) in
            self.particles[index] = particle
        })
        let maxDistance: Double = 5.0
//        let equibDistance: CGFloat = 2.0
        func callBack(index1: Int, index2: Int, inout object1: Particle, inout object2: Particle) {
    
            let d = (object1.x - object2.x).length
            
            if Double(d) < maxDistance {
                
                let force = (object1.x - object2.x).normalize() * CGFloat(cos(M_PI * Double(d) / (maxDistance * 2.0 / 3.0))) * (1.0 / d) * 500
                
                self.particles[index1].f -= force
                self.particles[index2].f += force

                
            }
            
            
        }
        // callback to add leonard jones forces to particles
        self.grid.runPairwiseSpatialFunction(callBack, maxDistance: Double(maxDistance))
        
        // add gravity, apply forces, step simulation forward
        for i in 0..<self.numParticles {
            var p = particles[i]
            
            p.f += CGPoint(x: 0.0, y: 9.8) * p.m
            p.f -= p.v  * 0.2
            
            p.applyForces(timeDelta)
            p.updatePosition(timeDelta)
            if p.x.y > CGFloat(self.grid.height) {
                p.x.y = CGFloat(2.0 * self.grid.height) - p.x.y
                p.v.y = -p.v.y * 0.1
            }
            if p.x.x > CGFloat(self.grid.width) {
                p.x.x = CGFloat(2.0 * self.grid.width) - p.x.x
                p.v.x = -p.v.x * 0.1
            }
            if p.x.y < 0.0 {
                p.x.y = -p.x.y
                p.v.y = -p.v.y * 0.1
            }
            if p.x.x < 0.0 {
                p.x.x = -p.x.x
                p.v.x = -p.v.x * 0.1
            }

            particles[i] = p
        }
        
//        swapBuffers(&self.currentGrid, buff2: &self.nextGrid)
        
        self.setNeedsDisplayInRect(self.bounds)
        
    }
    
    override func drawRect(dirtyRect: NSRect) {
        
        // when drawing individual circles
        // with no compiler optimizations we seem to be able to handle ~5000 particles with one timestep per frame
        // with whole-module optimization that number is a bit higher ~8000
        // most of the computation seems to be OpenGL overhead

        // if we render with a single call to CGContextFillRects we can hit ~10,000 with no compiler optimizations, ~45,000 with Whole Module Optimization
        
        let rect: CGRect = dirtyRect as CGRect
        
        let context: CGContextRef = NSGraphicsContext.currentContext()!.CGContext
        
        CGContextSetFillColorWithColor(context, CGColorCreateGenericRGB(1.0, 0.5, 0.5, 1.0))
        CGContextFillRect(context, rect)
        
        CGContextSetFillColorWithColor(context, CGColorCreateGenericRGB(0.5, 0.5, 1.0, 1.0))

        var rects: [CGRect] = []
        
        for i in 0..<self.numParticles {
            
            let p = particles[i]

            rects.append(CGRectInset(CGRect(x: p.x.x, y: p.x.y, width: 0.0, height: 0.0), -1, -1))
            
        }
        
        CGContextFillRects(context, rects, rects.count)
        
        
        
    }
    
}
