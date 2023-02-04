# Contact-angle-of-vesicles
## Introduction
  The tool in this repository is designed to analyze the contact angle of neighboring subcellular vesicles captured by fluorescence microsocopes including widefield, confocal and super-resolution images. Raw images were initially processed to enhance the ring structure for centerline recognition (Fig. 1A, B, and C). The junction points on the centerline are identified by skeleton analysis (Ref.1). From the same enhanced image, another branch in the analysis is to identify and label each individual vesicle. Then the center point of the junction and the neighboring vesicles which compose the junction are listed in the same row on the measurement table. The triangle where two neighboring vesicles surronded is used to define the vetex for contact angle measurement. Two angle values are presented in the result table. "Interest Angle" is the calculation result from the trigonometirc function, while "Angle measured" is the value directly measured by the point seletion tool of Fiji (Fig. 1E). For verifying the analysis result, the three points giving a contact angle listed in the same row are labeled as the same color on the enhanced image (Fig. 1D). The workflow of the script is offered in figure 2 to make it easier to be understood. 
## Demo image
![Fig1](https://user-images.githubusercontent.com/67047201/216746647-46ae1d5e-c15b-4218-b24e-550b80e34cfa.png)
## Workflow
![F2](https://user-images.githubusercontent.com/67047201/216746694-2a820436-4ff5-496b-9e44-8f8cb66c4a1f.png)
## Usage instruction
1. Download the script and open it in Fiji.
2. Open the vesicle image in Fiji with single channel.
3. Run the script directly.
4. Get result.
## Feedback
Made changes to the layout template or some other part of the code? Fork this repository, make your changes, and send a pull request. Do these codes help on your research? Please cite as the follows. Su, Y.A., Chiu, H.Y., Chang, Y.C., Sung, C.J., Chen, C.W., Xuang, R.T.,Huang, R., Hsu,S.C., Lin, S.S., Wang, H.C., Lin, Y.C., Hsu, J.C., Baskin, J.M., Chang, Z.F., Liu, Y.W. **NME3 binds to phosphatidic acid and mediates PLD6-induced mitochondrial tethering** JournalXX (2023) DOI
## Reference
1. Arganda-Carreras, I., Fernández-González, R., Muñoz-Barrutia, A., & Ortiz-De-Solorzano, C. (2010). 3D reconstruction of histological sections: Application to mammary gland tissue. Microscopy Research and Technique, 73(11), 1019–1029. doi:10.1002/jemt.20829
