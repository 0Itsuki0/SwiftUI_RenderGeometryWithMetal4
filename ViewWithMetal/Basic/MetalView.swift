//
//  MetalView.swift
//  ViewWithMetal
//
//  Created by Itsuki on 2025/09/16.
//

import SwiftUI
import Metal
import MetalKit

struct BasicMetalView: View {
    var body: some View {
        MetalView()
            .frame(width: 300, height: 300)
    }
}


struct MetalView: UIViewRepresentable {
    // An MTKView needs a reference to a Metal device object in order to create resources internally.
    // MTLDevice: The main Metal interface to a GPU that apps use to draw graphics and run computations in parallel.
    private let device: MTLDevice? = MTLCreateSystemDefaultDevice()
    
    // A queue that schedules GPU work
    private let commandQueue: MTL4CommandQueue?

    // Records a sequence of GPU commands to be committed to the command queue.
    private let commandBuffer: MTL4CommandBuffer?
    
    // allocator Managing the memory backing the encoding of GPU commands into command buffers.
    // We can have more than one allocators, one for each frame if we want to process multiple frames at once.
    private let commandAllocator: MTL4CommandAllocator?
    
    // Provides a mechanism to manage and provide resource bindings for buffers, textures, sampler states and other Metal resources
    private let argumentTable: MTL4ArgumentTable?
    
    // buffer for storing lineDataIn to the metal vertex function
    // one buffer for one argument to the shader functions
    private let vertexBuffer: MTLBuffer?

    // Pipeline states are responsible for rendering and computing passes, samplers, depth and stencil states, and etc.
    private let pipelineState: MTLRenderPipelineState?

    
    init() {
        
        // create command queue
        self.commandQueue = device?.makeMTL4CommandQueue()
        
        // Create command buffer.
        self.commandBuffer = device?.makeCommandBuffer()
        
        // Make command allocator
        self.commandAllocator = device?.makeCommandAllocator()


        // Create data buffer
        self.vertexBuffer = device?.makeBuffer(length: MemoryLayout<LineDataIn>.size, options: .storageModeShared)

        // since our lineDataIn never change, we can pre-set those ahead of time using the following.
        //
        // For demonstrating how we can update inputs to the metal shader on drawing, I will be setting buffer value within the delegate's draw(in view: MTKView) function instead.
        //
        // let vertexInStart = VertexIn(position: SIMD2<Float>(Float(-1), Float(-1)), color: SIMD4<Float>(Float(1.0), Float(1.0), Float(0.0), Float(1.0)))
        // let vertexInEnd = VertexIn(position: SIMD2<Float>(Float(1), Float(1)), color: SIMD4<Float>(Float(1.0), Float(1.0), Float(0.0), Float(1.0)))
        // var line: LineDataIn = .init(start: vertexInStart, end: vertexInEnd)
        // self.vertexBuffer = device?.makeBuffer(bytes: &line, length: MemoryLayout<LineDataIn>.size, options: .storageModeShared)
        
        
        // make argument table
        let argumentTableDescriptor = MTL4ArgumentTableDescriptor()
        argumentTableDescriptor.maxBufferBindCount = 1 // for line data in
        
        do {
            self.argumentTable = try device?.makeArgumentTable(descriptor: argumentTableDescriptor)
        } catch (let error) {
            print(error)
            self.argumentTable = nil
        }
        
        
        // make pipeline state
        guard let library = device?.makeDefaultLibrary() else {
            self.pipelineState = nil
            return
        }

        // create pipeline:
        //
        // An MTLRenderPipelineDescriptor instance configures the state of the pipeline to use during a rendering pass, including rasterization (such as multisampling), visibility, blending, tessellation, and graphics function state.
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        let vertexFunction = library.makeFunction(name: "vertexShader")
        pipelineDescriptor.vertexFunction = vertexFunction
        let fragmentFunction = library.makeFunction(name: "fragmentShader")
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        
        // set vertex descriptor if the vertex shader arguments uses per-vertex input attributes.
        //
        // Don't need it in this case because we are accessing the buffer directly
        //
        // let mdlVertexDescriptor = MDLVertexDescriptor()
        // // for position
        // mdlVertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: MDLVertexFormat.float2, offset: 0, bufferIndex: 0)
        // // for color
        // mdlVertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeColor, format: MDLVertexFormat.float4, offset: MemoryLayout<SIMD2<Float>>.stride, bufferIndex: 0)
        // mdlVertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<VertexIn>.stride)
        //
        // pipelineDescriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mdlVertexDescriptor)
        
        
        do {
            // create Pipeline states that are responsible for rendering and computing passes, samplers, depth and stencil states, and etc.
            self.pipelineState = try device?.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch (let error) {
            print(error)
            self.pipelineState = nil
        }
    }
    
    func makeUIView(context: Context) -> MTKView {
        let metalView = MTKView()
        // set up delegate
        metalView.delegate = context.coordinator
        
        // set up device
        metalView.device = self.device
        
        // set up color pixel format
        metalView.colorPixelFormat = .bgra8Unorm
       
        // Configuring the Drawing Behavior:
        //
        // The MTKView class supports three drawing modes:
        // - Timed updates: The view redraws its contents based on an internal timer. In this case, which is the default behavior, both isPaused and enableSetNeedsDisplay are set to false. Use this mode for games and other animated content that’s regularly updated.
        // - Draw notifications: The view redraws itself when something invalidates its contents, usually because of a call to setNeedsDisplay() or some other view-related behavior. In this case, set isPaused and enableSetNeedsDisplay to true. Use this mode for apps with a more traditional workflow, where updates happen when data changes, but not on a regular timed interval.
        // - Explicit drawing: The view redraws its contents only when you explicitly call the draw() method. In this case, set isPaused to true and enableSetNeedsDisplay to false. Use this mode to create your own custom workflow.
        metalView.isPaused = true
        metalView.enableSetNeedsDisplay = true
        
        // to set the background color to a different color then the default clear color
        // for example, to green
        // metalView.clearColor = MTLClearColorMake(0.0, 1.0, 0.0, 1.0)

        return metalView
    }

    func updateUIView(_ uiView: MTKView, context: Context) {
        // redraw the metal view on view update
        uiView.setNeedsDisplay()
    }

    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }


    class Coordinator: NSObject, MTKViewDelegate {
        private var parent: MetalView
        
        init(_ parent: MetalView) {
            self.parent = parent
        }
        
        // The view calls the mtkView(_:drawableSizeWillChange:) method whenever the size of the contents changes.
        // This happens when the window containing the view is resized, or when the device orientation changes (on iOS). This allows your app to adapt the resolution at which it renders to the size of the view.
        func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
            print(#function)
        }
        
        
        // The view calls the draw(in:) method whenever it’s time to update the view’s contents.
        // In this method, you create a command buffer, encode commands that tell the GPU what to draw and when to display it onscreen, and enqueue that command buffer to be executed by the GPU. This is sometimes referred to as drawing a frame. You can think of a frame as all of the work that goes into producing a single image that gets displayed on the screen. In an interactive app, like a game, you might draw many frames per second.
        func draw(in view: MTKView) {
            print(#function)
            guard let drawable = view.currentDrawable,
                  let renderPassDescriptor = view.currentMTL4RenderPassDescriptor else {
                print("failed to obtain properties from the view")
                return
            }
            
            guard let commandQueue = parent.commandQueue else {
                print("failed to get command queue")
                return
            }
            
            guard let commandBuffer = parent.commandBuffer else {
                print("failed to make command buffer")
                return
            }
            
            guard let pipelineState = parent.pipelineState else {
                print("failed to obtain pipeline state")
                return
            }
            
            guard let commandAllocator = parent.commandAllocator else {
                print("failed to obtain commandAllocator")
                return
            }
            
            guard let argumentTable = parent.argumentTable else {
                print("failed to obtain argumentTable")
                return
            }
            
            guard let vertexBuffer = parent.vertexBuffer else {
                print("failed to obtain data buffers.")
                return
            }

            // Prepare to use or reuse the allocator by resetting it.
            commandAllocator.reset()
            
            // Prepares a command buffer for encoding
            commandBuffer.beginCommandBuffer(allocator: commandAllocator)
            
            // create command encoder: An encoder that writes GPU commands into a command buffer.
            guard let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
                print("failed to create renderEncoder")
                return
            }
            
            // update buffer data.
            //
            // Buffers will not updated automatically, we are responsible for updating its content.
            //
            // in our case, since our LineDataIn will never change between frame to frame, we can also comment out the following and use the
            // `self.vertexBuffer = device?.makeBuffer(bytes: &line, length: MemoryLayout<LineDataIn>.size, options: .storageModeShared)`
            // above in our `init` method.
            let vertexInStart = VertexIn(position: SIMD2<Float>(Float(-1), Float(-1)), color: SIMD4<Float>(Float(1.0), Float(1.0), Float(0.0), Float(1.0)))
            let vertexInEnd = VertexIn(position: SIMD2<Float>(Float(1), Float(1)), color: SIMD4<Float>(Float(0.0), Float(1.0), Float(0.0), Float(1.0)))
            var line: LineDataIn = .init(start: vertexInStart, end: vertexInEnd)

            memcpy(vertexBuffer.contents(), &line, MemoryLayout<LineDataIn>.size)
            
            // Add the buffer with the line data to the argument table.
            argumentTable.setAddress(vertexBuffer.gpuAddress, index: 0)

            // Sets the viewport which that transforms vertices from normalized device coordinates to window coordinates.
            // not necessary in most of the scenarios.
            var viewPort = MTLViewport()

            viewPort.originX = 0
            viewPort.originY = 0
            // drawableSize:
            // If autoResizeDrawable is true, this property is updated automatically whenever the view’s size changes.
            // If autoResizeDrawable is false, set this value to change the size of the texture objects.
            // The default value is derived from the current view’s size, in native pixels
            //
            // Note: drawableSize is not of the same size as view.frame
            // in this case, view.frame is 300 * 300, whereas the drawable is 600 * 600
            viewPort.width = view.drawableSize.width
            viewPort.height = view.drawableSize.height
            viewPort.zfar = 1.0
            viewPort.znear = 0.0
            
            commandEncoder.setViewport(viewPort)
          
            // set render pipeline
            commandEncoder.setRenderPipelineState(pipelineState)
            
            // set Argument table
            commandEncoder.setArgumentTable(argumentTable, stages: .vertex)

            // draw line between the two vertices
            commandEncoder.drawPrimitives(primitiveType: .lineStrip, vertexStart: 0, vertexCount: 2)

            // Declares that all command generation from this encoder is complete and finalize the render pass.
            commandEncoder.endEncoding()

            // Closes a command buffer to prepare it for submission to a command queue.
            // Explicitly ending the command buffer allows use to reuse the MTL4CommandAllocator to start servicing other command buffers.
            // It is an error to call commit on a command buffer previously recording before calling this method.
            commandBuffer.endCommandBuffer()
            
            // Schedules a wait operation on the command queue to ensure the display is no longer using a specific Metal drawable.
            commandQueue.waitForDrawable(drawable)
            
            // Enqueues an array of command buffer instances for execution with a set of options.
            commandQueue.commit([commandBuffer])
            
            // Schedules a signal operation on the command queue to indicate when rendering to a Metal drawable is complete.
            // We are responsible for calling this method after committing all command buffers that contain commands targeting this drawable, and before calling present(), present(at:), or present(afterMinimumDuration:).
            commandQueue.signalDrawable(drawable)
            
            // Presents a drawable as early as possible.
            // We can also present it at a specific time using present(at:) or present(afterMinimumDuration:)
            drawable.present()
            
        }
    }
}
