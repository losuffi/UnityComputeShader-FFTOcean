# 一个真实水面模拟的解决方案

该方案在波形生成上，使用了Philips 频谱， 而后对其进行傅里叶逆变换生成一张顶点位移图，加上Tessellation方法，对Plane的顶点进行变化，通过顶点位移图，可以额外获取一张法线贴图。

## 1. 主要算法步骤

- 求一个Philips 频谱保存成贴图
- 对频谱进行时间参数处理后，进行逆傅里叶变换，得到顶点位移图
- 通过顶点位移图，可计算出法线贴图
- 使用Tessellation后，利用顶点位移图对顶点进行变换
- 获取相对深度（深水、浅水，着色）做Fresnel处理，利用法线随时间的变换，对折射图进行扰动采样
- 反射来源，可使用额外的摄像机渲染一张反射贴图（不准确，笔者觉得可以去掉不用，即昂贵，仅能代表平静的水面）
- 最后是水面阴影的问题，由于是透明的层级，unity的shadowmask 是无法让水面承接阴影的，笔者是用投影的方式，额外渲染的一张阴影贴图

## 2. 感想

-  这不是一个成熟的应用，而是一个大体上的框架，可以对整个流程进行增添或删改，使其更好的在实际项目中发挥作用
- 在水面着色，光照渲染上，笔者认为，使用BSDF 的完整渲染流去着色，必然能获得更好的效果。而这个项目中只是一个简陋的经验光照模型
- 在反射上，可以使用球谐函数，将反射信息进行预计算，并保存。可以使得水面的反射有更加逼真的效果。但这可以算是开启了另外一个项目了（Orz）

## 3.细节

- 关于快速傅里叶变换，笔者写了一篇更详细的说明，如果对快速傅里叶变换不够了解的，[可以去看看](https://losuffi.github.io/2018/10/16/Unity%E5%82%85%E9%87%8C%E5%8F%B6%E5%8F%98%E6%8D%A2%E7%9A%84%E5%BA%94%E7%94%A8%E2%80%94%E2%80%94%E7%9C%9F%E5%AE%9E%E6%B5%B7%E5%B9%B3%E9%9D%A2%E6%A8%A1%E6%8B%9F/)


## 4.效果图

![](https://github.com/losuffi/GraphicLab/raw/master/READMEPIC/A8.gif)

![](https://github.com/losuffi/GraphicLab/raw/master/READMEPIC/A13.gif)

