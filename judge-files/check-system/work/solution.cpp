#include<algorithm>
#include<iostream>
#include<cstdio>
#include<cmath>
#include<string>
#include<cstring>
#include<cstdlib>
#include<vector>
using namespace std;
#define fname1 ""//."
#define fname2 ""//put.txt"
#define sz 100*1000*2
#define inf 1000*1000*1000


int n, m, color[sz];
vector<int> g[sz];
bool used[sz];
vector<int> ans;
 
void dfs (int v) {
	color[v] = 1;
	used[v] = true;
	for (size_t i=0; i<g[v].size(); ++i){
		int to = g[v][i];
		if( color[to]==1 ){
			printf("-1");
			exit(0);
		}
		if( !used[to] )
			dfs(to);
	}
	ans.push_back(v);
	color[v] = 2;
}
 

int main(){
//	freopen("p.in", "r", stdin);
//	freopen("p.out", "w", stdout);
	scanf("%d%d", &n, &m);
	for(int i=1, x, y; i<=m; i++){
		scanf("%d%d", &x, &y);
		g[x].push_back(y);
	}	
	for (int i=1; i<=n; ++i)
		used[i] = false;
	for (int i=1; i<=n; ++i)
		if (!used[i])
			dfs(i);
	reverse( ans.begin(), ans.end() );
	for(int i=0; i<(int)ans.size(); i++)
		printf("%d ", ans[i]);

	return 0;
}
