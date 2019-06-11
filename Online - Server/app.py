import sys
import os
import torch
import torchvision
from torchvision import transforms as T
from werkzeug.utils import secure_filename
import PIL
from PIL import Image
import numpy as np
from numpy import *
import math
from flask import Flask, render_template, jsonify, request, make_response, send_from_directory, abort

sys.path.append('..')


""" Initializing Flask """
app = Flask(__name__)
UPLOAD_FOLDER = './images'
base_dir = '~/server'
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
basedir = os.path.abspath(os.path.dirname(__file__))
ALLOWED_EXTENSIONS = set(['jpeg', 'png', 'jpg', 'JPG', 'PNG', 'gif', 'GIF'])

## Loading Model
model = torchvision.models.resnet101()
model.fc = torch.nn.Linear(2048, 15)
net_dict = torch.load('restnet101_0.96.pth', map_location='cpu')
model.load_state_dict(net_dict['net'])

##model = torchvision.models.densenet161(pretrained=False)
##model.classifier = torch.nn.Linear(2208, 15)
##model = torch.load('densnet_0.9433333333333334.pkl', map_location = 'cpu')
##model.fc = torch.nn.Linear(2208, 15)
##model.load_state_dict(net_dict['net'])

transform = T.Compose([T.Resize(256), 
                        T.RandomCrop(224), 
                        T.ToTensor(), 
                        T.Normalize((0.5, 0.5, 0.5), (0.5, 0.5, 0.5)),
                        ])

## Definite the name of birds
birdsname = ['Grey Butcherbird', 'Grey Fantail', 'House Sparrow', 'Laughing Kookaburra',
             'Little Wattlebird', 'New Holland Honeyeater', 'Noisy Miner', 'Pied Currawong',
             'Rainbow Lorikeet', 'Red Wattlebire', 'Red-browed Finch',
             'Red-whiskered Bulbul','Silvereye', 'Spotted Pardalote', 'Spotted Turtle Dove']

def allowd_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1] in ALLOWED_EXTENSIONS

def softmax(inmatrix):
    """Compute softmax values for each sets of images in x."""
    ##x = x - np.max(x)
    ##exp_x = np.exp(x)
    ##e_x = exp_x / np.sum(exp_x)
    ##return e_x
    m, n = np.shape(inmatrix)
    outmatrix = np.mat(np.zeros((m, n)))
    soft_sum = 0
    for idx in range(n):
        outmatrix[0, idx] = math.exp(inmatrix[0, idx])
        soft_sum += outmatrix[0, idx]
    for idx in range(n):
        outmatrix[0, idx] = outmatrix[0, idx] / soft_sum
    return outmatrix

@app.route('/up_photo', methods=['POST'], strict_slashes=False)
def api_upload():
    ## Accepting image
    file_dir = os.path.join(base_dir, app.config['UPLOAD_FOLDER'])
    if not os.path.exists(file_dir):
        os.makedirs(file_dir)
    f = request.files['photo']

    if f and allowd_file(f.filename):
        fname = secure_filename(f.filename)
        print(fname)
        f.save(os.path.join(file_dir, fname))

        ## Processing image
        image = PIL.Image.open(os.path.join(file_dir, fname))
        image = transform(image).reshape(1, 3, 224, 224)
        result = model(image).argmax()
        r = int(result)
        output = model(image)
        ##new_array = []
        ##for i in range (len(output)):
        ##    new_array.append(output[i])
        ##new_array = np.array(newlist)
            ##item = output[i]
            ##for j in range(0,1):
              ##  new_array.append(item[j]])
        probability = softmax(output)
        test = probability.argmax()
        test1 = int(test)
        max_pro = np.max(probability)
        bird = birdsname[r]

        return jsonify({'success': 0, 'birds': bird, 'location': r, 'probability': max_pro, 'length': len(output)})
    else:
        return jsonify({'error': 1, 'birds': 'error'})



