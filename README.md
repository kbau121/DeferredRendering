Deferred Rendering and Screen-Space Reflection
======================

<div align="center">
  <img src="output/final.png"/>
</div>

This implementation of a physically based shader utilizes deferred rendering to complete the image in multiple passes. Pass order is as follows:
1. Environment Map generation
2. Geometry Buffer generation
3. Screen Space Reflection pass
4. Screen Space Reflection Blur (rough surface reflections)
5. Combination to final image

This allows us to create rough surface reflections in real-time.

| Without SSR  | With SSR |
| ------------- | ------------- |
| ![](output/beforeSSR.png)  | ![](output/final.png)  |

Intermediate Results
----------------------

<table>
  <tr>
    <th>Blur Combined</th>
    <td><img src="output/glossFinal.png"/></td>
  </tr>
  <tr>
    <th>Blur Level 0</th>
    <td><img src="output/gloss0.png"/></td>
  </tr>
  <tr>
    <th>Blur Level 1</th>
    <td><img src="output/gloss1.png"/></td>
  </tr>
  <tr>
    <th>Blur Level 4</th>
    <td><img src="output/gloss4.png"/></td>
  </tr>
</table>
