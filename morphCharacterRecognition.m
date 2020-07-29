% This function takes separated characters as input and recognizes
% characters @ and +

function  [atCharactersOutput, plusCharactersOutput] = morphCharacterRecognition(character_image)

% detect @ to find location of email adress
%% using erosion and dilation with @ as structuring element
%try first just erosion and dilation with @ as structuring element

atFilter2 = imread('newAtCharacter.bmp');
atFilter2 = imbinarize(atFilter2, 0.5);

atFiltersize2 = size(atFilter2);

nBoxes = size(character_image);
nAts = 0;
atCharacters(1).boolAtDetected=0;

%while no @ is found
oneIter = 0;
while atCharacters(1).boolAtDetected == 0 && oneIter<3
    
    %loop through all letters in image
  if nBoxes(2)>1
    for i = 1:nBoxes(2)
        nCharacters = size(character_image(i).characters);
        
        %get average height of letters in textbox
        totalheight = 0;
        for j = 1:nCharacters(2)
            totalheight = totalheight + character_image(i).characters(j).box(4);
        end
        avgheight = totalheight/nCharacters(2);
        
        for j = 1:nCharacters(2)
            %resize mask
            scalex = character_image(i).characters(j).box(3)/(atFiltersize2(2)-1);
            scaley = character_image(i).characters(j).box(4)/(atFiltersize2(1)-1);
            %don't allow too much scaling difference in x and y direction
            if (scaley/scalex) > 0.9 && (scalex/scaley) > 0.9 && (scalex) > 0.7
                
                atFilter2resized = imresize(atFilter2, 'Scale', [scaley, scalex]);

                %dilate letterImg with size dependent filter to detect more
                if scalex>1
                    sizeDilate = 5;
                else
                    sizeDilate = 3;
                end
                
                se = strel('cube', sizeDilate);
                dilatedImg = imdilate(character_image(i).characters(j).letterImg,se); 
                
                if oneIter == 2
                    dilatedImg = imdilate(dilatedImg,se);
                end
                erodedImg = imerode(dilatedImg, atFilter2resized);
                
                %average of letter-area in word
                isCandidate = 1;
                if character_image(i).characters(j).box(4)<=avgheight
                    isCandidate = 0;
                end
                %first letter of the word is not @ (for valid email adress)
                if j == 1
                    isCandidate = 0;
                end
                
                %only let center of eroded pass (@ should be in center)
                erodedImgSize = size(erodedImg);
                lmin = round(erodedImgSize(2)/2)-round(0.1*erodedImgSize(2));
                lmax = round(erodedImgSize(2)/2)+round(0.1*erodedImgSize(2));
                mmin = round(erodedImgSize(1)/2)-round(0.1*erodedImgSize(1));
                mmax = round(erodedImgSize(1)/2)+round(0.1*erodedImgSize(1));
                
                for l=1:erodedImgSize(2)
                    for m=1:erodedImgSize(1)
                        if (mmin <= m) && (m <= mmax) && (lmin <= l) && (l <= lmax)
                            erodedImg(m,l) = erodedImg(m,l);
                        else
                            erodedImg(m,l) = 0;
                        end
                    end
                end

                %if overlap is found, it is considered as a potential @
                if ~isempty(nonzeros(erodedImg)) && isCandidate == 1
%                     figure(i+20); 
%                     subplot(1,4,1)
%                     imshow(character_image(i).characters(j).letterImg);
%                     subplot(1,4,2)
%                     imshow(atFilter2resized);
%                     subplot(1,4,3)
%                     imshow(dilatedImg);
%                     subplot(1,4,4)
%                     imshow(erodedImg);
                    
                    nAts = nAts+1;
                    atCharacters(nAts).boolAtDetected=1;
                    atCharacters(nAts).textbox = character_image(i).box;
                    atCharacters(nAts).letterbox = character_image(i).characters(j).box;
                    atCharacters(nAts).letterImg = character_image(i).characters(j).letterImg;
                    atCharacters(nAts).dilatedletterImg = imdilate(erodedImg, atFilter2resized);
                end
            end
        end
    end
  end
    
    se = strel('cube', 3);
    if oneIter<1
        atFilter2 = imerode(atFilter2,se);
    end
    oneIter=oneIter+1;

end

 %% Tried and Failed: using max overlap of the structuring element @
% %this method ALWAYS outputs exactly one detected @ (also if there is no @...)
% 
% atFilter1 = imread('maskAtCharacter.bmp');
% atFilter1 = imbinarize(atFilter1, 0.5);
% atFilter2 = imread('newAtCharacter.bmp');
% atFilter2 = imbinarize(atFilter2, 0.5);
% %newAtCharacter.bmp
% 
% %erode filter to let more @'s pass
% %se = strel('cube', 3);
% %atFilter2 = imerode(atFilter2,se);
% 
% atFiltersize1 = size(atFilter1);
% atFiltersize2 = size(atFilter2);
% 
% nBoxes = size(character_image);
% atCharacters(1).boolAtDetected=0;
% 
% %loop through all letters in image
% for i = 1:nBoxes(2)
%     nCharacters = size(character_image(i).characters);
%     for j = 1:nCharacters(2)
%         %resize mask
%         scaley = character_image(i).characters(j).box(3)/(atFiltersize2(2)-1);
%         scalex = character_image(i).characters(j).box(4)/(atFiltersize2(1)-1);
%         %don't allow too much scaling difference in x and y direction
%         if (scaley/scalex) > 0.7 && (scaley) > 0.3
%             atFilter2resized = imresize(atFilter2, 'Scale', [scalex, scaley]);
%             %atFilter2resized = imresize(atFilter2, scaley);
% 
% %                 if i == 12 && j == 1
% %                     figure(7); imshow(atFilter2resized);
% %                     %scale
% %                 end
% 
%             %resize filter or img that they are the same size
%             binaryLetter = imbinarize(character_image(i).characters(j).letterImg,0.1);
%             lettersize = size(binaryLetter);
%             filtersize = size(atFilter2resized);
%             if lettersize(1) > filtersize(1)
%                 if lettersize(2) > filtersize(2)
%                     binaryLetter = imcrop(binaryLetter, [0,0, filtersize(2), filtersize(1)]);
%                 else
%                     binaryLetter = imcrop(binaryLetter, [0,0, filtersize(2), lettersize(1)]);
%                     atFilter2resized = imcrop(atFilter2resized, [0,0, filtersize(2), lettersize(1)]);        
%                 end
%             else if lettersize(1) < filtersize(1)
%                     if lettersize(2) <= filtersize(2)
%                         atFilter2resized = imcrop(atFilter2resized, [0,0, lettersize(2), lettersize(1)]);
%                     else
%                         binaryLetter = imcrop(binaryLetter, [0,0, lettersize(2), filtersize(1)]);
%                         atFilter2resized = imcrop(atFilter2resized, [0,0, lettersize(2), filtersize(1)]);        
%                     end
%                 else
%                     if lettersize(2) > filtersize(2)
%                         binaryLetter = imcrop(binaryLetter, [0,0, lettersize(2), filtersize(1)]);
%                     else if lettersize(2) < filtersize(2)
%                             atFilter2resized = imcrop(atFilter2resized, [0,0, lettersize(2), filtersize(1)]);
%                         end
%                     end
%                 end
%             end
% 
% %                 disp('new size ')
% %                 lettersize = size(binaryLetter)
% %                 filtersize = size(atFilter2resized)
% 
%             binarySubtraction = imbinarize(binaryLetter-atFilter2resized, 0.5);
%             binaryChange = imbinarize(binaryLetter-binarySubtraction,0.5);
%             character_image(i).characters(j).binaryChange = binaryChange;
% 
%         else
%             character_image(i).characters(j).binaryChange = 0;
%         end
% 
%     end
% end
% 
% %find max RELATIVE overlap of the whole image
% lettermax = 0;
% for i = 1:nBoxes(2)
%         nCharacters = size(character_image(i).characters);
%         for j = 1:nCharacters(2)
%             count = sum(character_image(i).characters(j).binaryChange(:))/sum(imbinarize(character_image(i).characters(j).letterImg(:),0.5));
%             if count > lettermax
%                 atCharacters(1).boolAtDetected=1;
%                 atCharacters(1).textbox = character_image(i).box;
%                 atCharacters(1).letterbox = character_image(i).characters(j).box;
%                 atCharacters(1).letterImg = character_image(i).characters(j).letterImg;
%                 lettermax = count;
%             end
%         end
% end

 %% Hit-miss

plusFilter = imread('newPlusCharacter.bmp');
plusFilter = imbinarize(plusFilter, 0.5);

plusFiltersize = size(plusFilter);

nBoxes = size(character_image);
nPlus = 0;
plusCharacters(1).boolPlusDetected=0;

%while no + is found
oneIter = 0;
while plusCharacters(1).boolPlusDetected == 0 && oneIter<3
    
    %loop through all letters in image
  if nBoxes(2)>1
    for i = 1:nBoxes(2)
        nCharacters = size(character_image(i).characters);
        
        totalheight = 0;
        for j = 1:nCharacters(2)
            totalheight = totalheight + character_image(i).characters(j).box(4);
        end
        avgheight = totalheight/nCharacters(2);
        
        for j = 1:nCharacters(2)
            %resize mask
            scalex = character_image(i).characters(j).box(3)/(plusFiltersize(2)-1);
            scaley = character_image(i).characters(j).box(4)/(plusFiltersize(1)-1);
            %don't allow too much scaling difference in x and y direction
            if (scaley/scalex) > 0.8 && (scalex/scaley) > 0.8 && (scalex) > 0.5
                plusFilterresized = imresize(plusFilter, [character_image(i).characters(j).box(4)+1, character_image(i).characters(j).box(3)+1]);

                %get boundary filter
                if scaley>1
                    sizeDilate = round(4.5*scalex);
                    sizeErode = round(4.5*scalex);
                else
                    sizeDilate = round(3*scalex);
                    sizeErode = round(3*scalex);
                end
                
                seDilate = strel('diamond', sizeDilate);
                seErode = strel('square', sizeErode);
                
                dilatedF = imdilate(plusFilterresized,seDilate);
                if oneIter == 1
                    seDilate2 = strel('square', 3);
                    F2 = imdilate(dilatedF,seDilate2) - dilatedF;
                    plusFilterresizedUsed = imerode(plusFilterresized,seErode);
                else if oneIter == 2
                        F2 = imdilate(imdilate(dilatedF,se),se) - imdilate(dilatedF,se);
                        plusFilterresizedUsed = imerode(plusFilterresized,se);
                    else
                        F2=dilatedF-plusFilterresized;
                        plusFilterresizedUsed = plusFilterresized;
                    end
                end

%                 if i == 12 && j == 1
%                     figure(7); imshow(F2);
%                     %scale
%                 end
                
                isCandidatePlus = 1;
                if character_image(i).characters(j).box(4)>=avgheight
                    isCandidatePlus = 0;
                end
                
                %Hit-Miss
                hitMiss = bwhitmiss(character_image(i).characters(j).letterImg,plusFilterresizedUsed,F2);
                %only let center of hit-miss pass (+ should be in center)
                hitMissSize = size(hitMiss);
                lmin = round(hitMissSize(2)/2)-round(0.1*hitMissSize(2));
                lmax = round(hitMissSize(2)/2)+round(0.1*hitMissSize(2));
                mmin = round(hitMissSize(1)/2)-round(0.1*hitMissSize(1));
                mmax = round(hitMissSize(1)/2)+round(0.1*hitMissSize(1));
                
                for l=1:hitMissSize(2)
                    for m=1:hitMissSize(1)
                        if (mmin <= m) && (m <= mmax) && (lmin <= l) && (l <= lmax)
                            hitMiss(m,l) = hitMiss(m,l);
                        else
                            hitMiss(m,l) = 0;
                        end
                    end
                end
                
                if ~isempty(nonzeros(hitMiss)) && isCandidatePlus == 1
%                     figure(i+10); 
%                     subplot(1,3,1)
%                     imshow(character_image(i).characters(j).letterImg);
%                     subplot(1,3,2)
%                     imshow(plusFilterresizedUsed);
%                     subplot(1,3,3)
%                     imshow(F2);
%                     subplot(4,1,4)
%                     imshow(bwhitmiss(character_image(i).characters(j).letterImg,plusFilterresizedUsed,F2));
                       
                    nPlus = nPlus+1;
                    plusCharacters(nPlus).boolPlusDetected=1;
                    plusCharacters(nPlus).textbox = character_image(i).box;
                    plusCharacters(nPlus).letterbox = character_image(i).characters(j).box;
                    plusCharacters(nPlus).letterImg = character_image(i).characters(j).letterImg;
                end
            end
        end
    end
  end
    
    oneIter=oneIter+1;

end


%% output

atCharactersOutput = atCharacters;
plusCharactersOutput = plusCharacters;


