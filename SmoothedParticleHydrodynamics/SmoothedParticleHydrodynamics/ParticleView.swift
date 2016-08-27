//
//  ParticleView.swift
//  SmoothedParticleHydrodynamics
//
//  Created by Holmes Futrell on 8/25/16.
//  Copyright © 2016 Holmes Futrell. All rights reserved.
//

import Cocoa

class ParticleView : NSView {
    
    var particles: [Particle] = []
    var renderTimer: NSTimer!
    
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
        
        NSLog("particle view init")
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
        
        for i in 0..<10 {
            let initialPosition: CGPoint = CGPoint(x: 32, y: 48)
            let initialVelocity: CGPoint = CGPoint(x: 32, y: 0) + randomVector() * 5.0
            particles.append( Particle(x: initialPosition, v: initialVelocity, m: 1.0) )
        }
        
        for i in 0..<particles.count {
            
            var p = particles[i]
            
            p.applyForce(CGPoint(x: 0.0, y: 9.8) * p.m, timeDelta: timeDelta)
            p.updatePosition(timeDelta)
            
            if p.x.y > self.bounds.height {
                p.x.y = 2.0 * self.bounds.height - p.x.y
                p.v.y = -p.v.y * 0.5
            }
            if p.x.x > self.bounds.width {
                p.x.x = 2.0 * self.bounds.width - p.x.x
                p.v.x = -p.v.x * 0.5
            }

            
            particles[i] = p
        
        }
        
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
        
        for i in 0..<particles.count {
            
            let p = particles[i]

            rects.append(CGRectInset(CGRect(x: p.x.x, y: p.x.y, width: 0.0, height: 0.0), -1, -1))
            
        }
        
        CGContextFillRects(context, rects, rects.count)
        
        
        
    }
    
}
