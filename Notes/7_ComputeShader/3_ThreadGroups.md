# Thread groups

**Links:**

- https://docs.unity3d.com/6000.3/Documentation/Manual/class-ComputeShader.html
- https://discussions.unity.com/t/compute-shader-sv_dispatchthreadid-to-texture-coord/889976
- https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/sm5-attributes-numthreads

## What is a thread group ?

// -> thread group = composed of numthreads(X,Y,Z) threads, every thread inside a thread group will calculate the value of a texel

hierarchy:
- grid of XYZ thread groups
    - composed of XYZ threads deoeding on numthreads 

## Grid of thread groups

<img src="https://learn.microsoft.com/en-us/windows/win32/direct3dhlsl/images/threadgroupids.png" alt="Explanation of thread groups structure" width="600"/>

// Every thread group is executed on an independant compute unit because different groups of thread cannot be synchronized, in fact we have no control on the order
// that will be used to process the thread groups. Thread synchronization can only happen on thread within the same group.

// => the texture is split into groups of threads called thread groups that will be processed on different compute unit. To calculate the number of thread groups we divide the size
//    of our texture by the number of threads we use for each dimension and we generate a grid of thread group on the texture

## Thread group related semantics

// Note: SV_GroupID = index of a group that will be executed in the compute shader
//        |-> numthreads = total of threads for each groups
//              |-> SV_GroupThreadId = id of each individual thread

// SV_DispatchThreadID = [(SV_GroupID) * (numthreads)] + (SV_GroupThreadID)
// -> sum of the number of threads for each group we use + index of each thread

### SV_DispatchThreadID semantic
The function use the semantic `SV_DispatchThreadID` as argument. This semantic is a `uint3` (3D vector of unsigned ints) that refers to the indexes of every thread

