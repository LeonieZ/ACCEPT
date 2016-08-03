#include <string>
#include <iostream>
#include <sstream>
#include <map>
#include <vector>
#include <algorithm>
#include <boost/algorithm/string.hpp>
#include "rapidxml.hpp"
#include "rapidxml_utils.hpp"
#include "mex.h"

using namespace std;
using namespace rapidxml;

typedef xml_node<>* xmlnode;
typedef vector<xmlnode> list_node;
typedef map<int,list_node> dict_i_to_list;
typedef map<string,dict_i_to_list> dict_str_to_dict;

inline string trimmed(const string &s);
template <typename T> T tonum(const string &s);
template <typename T> ostream& operator<<(ostream &out, vector<T> v);
mxArray* parse_arrays(list_node arrays);
mxArray* parse_family(list_node family);

template <> int tonum<int>(const string &s) {
    return atoi(s.c_str());
}

template <> double tonum<double>(const string &s) {
    return atof(s.c_str());
}

template <typename T> vector<T> tonum(vector<string> v) {
    vector<T> tokens(v.size());
    for (int i = 0; i < v.size(); i++) {
        tokens[i] = tonum<T>(v[i]);
    }
    return tokens;
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
    char filename[200];
    mxGetString(prhs[0], filename, 200);
    file<> xml_file(filename);
    xml_document<> doc;
    doc.parse<0>(xml_file.data());
    list_node root;
    root.push_back(doc.first_node());
    plhs[0] = parse_family(root);
}

mxArray* parse_family(list_node family)
{
    dict_str_to_dict fields;
    for (int sibling = 0; sibling < family.size(); sibling++) {
        for (xmlnode
             child = family[sibling]->first_node(); 
             child; 
             child = child->next_sibling()) {
            if (child->type() == node_element) {
                fields[child->name()][sibling].push_back(child);
            }
        }
    }

    const char** fieldnames = new const char*[fields.size()];
    bool contract = true;
    int i = 0;
    for (dict_str_to_dict::iterator 
         field_family = fields.begin(); 
         field_family != fields.end(); 
         field_family++) {
        fieldnames[i++] = field_family->first.c_str();
        if (field_family->second.size() > 1) {
            contract = false;
        }
    }
    mxArray* data = mxCreateStructMatrix((contract) ? 1 : family.size(), 1, 
                                         fields.size(), fieldnames);
    delete[] fieldnames;

    char* end_p;
    double d;
    bool has_type;
    mxArray* value;
    char* type;
    for (dict_str_to_dict::iterator 
         field_family = fields.begin(); 
         field_family != fields.end(); 
         field_family++) {
        for (dict_i_to_list::iterator 
             sibling_children = field_family->second.begin(); 
             sibling_children != field_family->second.end(); 
             sibling_children++) {
            if (sibling_children->second[0]->first_node() == 0) {
                continue;
            }
            has_type = sibling_children->second[0]->first_attribute("type") != 0;
            if (has_type) {
                type = sibling_children->second[0]->first_attribute("type")->value();
            }
            if (has_type && (strcmp(type, "dble") || strcmp(type, "int"))) {
                value = parse_arrays(sibling_children->second);
            } else if (sibling_children->second[0]->first_node()->type() == node_element) {
                value = parse_family(sibling_children->second);
            } else {
                int size = sibling_children->second.size();
                if (size > 1) {
                    value = mxCreateCellArray(1, &size);
                    for (i = 0; i < size; i++) {
                        mxSetCell(value, i, mxCreateString(
                            trimmed(sibling_children->second[i]->value()).c_str()));
                    }
                } else {
                    value = mxCreateString(
                        trimmed(sibling_children->second[0]->value()).c_str());
                }
            }
            mxSetField(data, (contract) ? 0 : sibling_children->first, 
                       field_family->first.c_str(), value);
        }
    }

    return data;
}

mxArray* parse_arrays(list_node arrays)
{
    int n_arrays = arrays.size();
    mxArray* data = mxCreateCellArray(1, &n_arrays);
    bool has_size;
    for (int i_array = 0; i_array < n_arrays; i_array++) {
        vector<int> dims;
        has_size = arrays[i_array]->first_attribute("size") != 0;
        if (has_size) {
            vector<string> tokens;
            string size_attr = trimmed(arrays[i_array]->first_attribute("size")->value());
            boost::split(tokens, size_attr, boost::is_any_of(" \t\n"), 
                         boost::token_compress_on);
            dims = tonum<int>(tokens);
        } else {
            dims = vector<int>(1, 1);
        }
        int n_dims = dims.size();
        int* dims_arr = new int[n_dims];
        for (int i = 0; i < n_dims; i++) {
            dims_arr[i] = dims[i];
        }
        mxArray* mx_array = mxCreateNumericArray(n_dims, dims_arr, mxDOUBLE_CLASS, mxREAL);
        delete[] dims_arr;
        mxSetCell(data, i_array, mx_array);
        double* arr = mxGetPr(mx_array);
        vector<double> col(dims[0]);
        list_node node_index(n_dims);
        vector<int> multi_index(n_dims, 1);
        if (n_dims > 1) {
            node_index.back() = arrays[i_array]->first_node("vector");
            for (int i = n_dims-2; i > 0; i--) {
                node_index[i] = node_index[i+1]->first_node();
            }
        }
        int running_index = 0;
        while (true) {
            string col_str;
            if (n_dims == 1) {
                col_str = arrays[i_array]->value();
            } else {
                col_str = node_index[1]->value();
            }
            col_str = trimmed(col_str);
            vector<string> tokens;
            boost::split(tokens, col_str, boost::is_any_of(" \t\n"), 
                         boost::token_compress_on);
            col = tonum<double>(tokens);
            for (int i = 0; i < dims[0]; i++) {
                arr[running_index++] = col[i];
            }
            if (n_dims == 1) {
                break;
            }
            multi_index[1]++;
            for (int i = 1; i < n_dims; i++) {
                if (multi_index[i] > dims[i]) {
                    if (i < n_dims-1) {
                        multi_index[i] = 1;
                        multi_index[i+1]++;
                    } else
                        break;
                } else {
                    node_index[i] = node_index[i]->next_sibling();
                    for (int j = i-1; j >= 1; j--) {
                        node_index[j] = node_index[j+1]->first_node();
                    }
                    break;
                }
            }
            if (multi_index.back() > dims.back()) {
                break;
            }
        }
    }
    if (n_arrays == 1) {
        mxArray* data_cell = data;
        data = mxGetCell(data_cell, 0);
        mxSetCell(data_cell, 0, NULL);
        mxDestroyArray(data_cell);
    }
    return data;
}

inline string trimmed(const string &s) {
    int i = 0, n = s.size();
    while (isspace(s[i])) {
        i++;
    }
    while (isspace(s[n-1])) {
        n--;
    }
    return s.substr(i, n-i);
}

template <typename T>
ostream& operator<<(ostream &out, vector<T> v) {
    for (typename vector<T>::iterator it = v.begin(); it != v.end(); it++) {
        out << *it << ' ';
    }
    return out;
}

