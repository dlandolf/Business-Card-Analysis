clc;
close all;
clear;

%read in already preprocessed image of business card

ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/businessCardBelleRive.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/business_card_example_cropped.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/sterisCard.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/responsebiomedCard.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/acumedCard.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/card8.png';%hologic
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/diasorinCard.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/mandalaosCard.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/card7.png'; %acumed
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/card9.png'; %response
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/card12.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/businessCardAtimg2.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/dkshCard.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/businessCardZoomed.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/archletCard.png';
%ImgFileName = '/Users/dominiclandolf/ImageProcessing_Project/card11.png';

businessCardImage = imread(ImgFileName);

%% resize so all images have similar size
cardsize = size(businessCardImage);
if cardsize(1) < 800
    disp('Image quality may be too bad for correct detection!')
end

if cardsize(1) < 1200
    factor = 1200/cardsize(1);
else if cardsize(1) > 1500
        factor = 1500/cardsize(1); 
else 
    factor = 1;
    end
end

businessCardImage = imresize(businessCardImage, factor);

%% extract the area of text
%outputs the cropped images in a struct with location in original image stored
textAreas = textAreaDetection(businessCardImage);

%% separate characters with vertical projection method
characters = separateCharacters(textAreas);

%% plot results
nBoxes = size(characters);

contactLabeledImg = businessCardImage;
contact_text = cell(1,1);
contact_text{1} = ['Contact Information'];
xMin = 5000;
yMin = 5000;
idx=0;
for i = 1:nBoxes(2)
    if yMin > characters(i).box(2) && characters(i).isTextBox == 1
        yMin = characters(i).box(2);
        idx=i;
    end
end
pos = [characters(idx).box(1), characters(idx).box(2)-40];
    contactLabeledImg = insertText(contactLabeledImg,pos,contact_text,'FontSize',25,'BoxColor',...
        'white','BoxOpacity',0.4,'TextColor','red');

figure(1); imshow(contactLabeledImg);
hold on;
for i = 1:nBoxes(2)
    if characters(i).isTextBox == 1
        rectangle('Position',[characters(i).box(1) characters(i).box(2) characters(i).box(3) characters(i).box(4)],'EdgeColor','red');
        hold on;
    end 
end
title('Bounding boxes of text lines');
hold off;

%show all the detected rectangles of the individual letters in image
figure(2); imshow(businessCardImage);
figure(2);
hold on;
if nBoxes(2)>1
    for i = 1:nBoxes(2)
        nCharacters = size(characters(i).characters);
        for j = 1:nCharacters(2)
            if characters(i).isTextBox == 1
                rectangle('Position',[characters(i).characters(j).box(1) characters(i).characters(j).box(2) characters(i).characters(j).box(3) characters(i).characters(j).box(4)],'EdgeColor','red');
                hold on;
            end
        end
    end
else
    disp('No text detected!')
end
title('Bounding boxes of letters');
hold off;

%% Optical character recognition

[recognizedAts, recognizedPlus] = morphCharacterRecognition(characters);

%% plot results
labeledImg = businessCardImage;

nAts = size(recognizedAts);
if recognizedAts(1).boolAtDetected == 1
    email_text = cell(1,1);
    email_text{1} = ['E-Mail Adress'];
    for i = 1:nAts(2)
        pos = [recognizedAts(i).textbox(1), recognizedAts(i).textbox(2)-40];
        labeledImg = insertText(labeledImg,pos,email_text,'FontSize',25,'BoxColor',...
            'white','BoxOpacity',0.4,'TextColor','red');
    end
else
    disp('No @ was detected.')
end

nPlus = size(recognizedPlus);
if recognizedPlus(1).boolPlusDetected == 1
    phone_text = cell(1,1);
    phone_text{1} = ['Telephone number'];
    for i = 1:nPlus(2)
        pos = [recognizedPlus(i).textbox(1), recognizedPlus(i).textbox(2)-40];
        labeledImg = insertText(labeledImg,pos,phone_text,'FontSize',25,'BoxColor',...
            'white','BoxOpacity',0.4,'TextColor','blue');
    end
else
    disp('No + was detected.')
end


figure(4); imshow(labeledImg);
figure(4);
hold on;
if recognizedAts(1).boolAtDetected == 1
    for i = 1:nAts(2)
        %rectangle('Position',recognizedAts(i).letterbox ,'EdgeColor','red');
        rectangle('Position',recognizedAts(i).textbox ,'EdgeColor','red');
        hold on;
    end
end
if recognizedPlus(1).boolPlusDetected == 1
    for i = 1:nPlus(2)
        %rectangle('Position',recognizedPlus(i).letterbox ,'EdgeColor','blue');
        rectangle('Position',recognizedPlus(i).textbox ,'EdgeColor','blue');
        hold on;
    end
end

title('Email Adress and Phone number');
hold off;
