from PIL import Image

for i in range(10):
    im = Image.open("img"+str(i)+".png")
    rgb_im = im.convert('RGB')
    rgb_im.save("img"+str(i)+".jpg")