%% @author zhangkl@lilith
%% @doc test.
%% 2016
%% QQ 452211545
%% TEL 15626011556
%% 游戏服务器开发

-module(test).

%% ====================================================================
%% API functions
%% ====================================================================
-export([test/0,
         apsaradb/3]).

test() ->
    apsaradb("gfekjmlinhpoqdutsrvcbxwyaBAzEDGFC", "gfkmljnipqoheutsvrdcxywbBAEGFDCza",
             {"abcdefghijklmnopqrstuvwxyzABCDEFG", "Wec_otphsaeamDaB_iert_otolm_ejn_A"}).

apsaradb("gfekjmlinhpoqdutsrvcbxwyaBAzEDGFC" = MidString,  %中
         "gfkmljnipqoheutsvrdcxywbBAEGFDCza" = PostString,  %后
         {"abcdefghijklmnopqrstuvwxyzABCDEFG" = OrderString, "Wec_otphsaeamDaB_iert_otolm_ejn_A" = DestString}) ->
    %%得到层次遍历结果
    LevelString = get_level_traversal_string(MidString, PostString),
    get_password_string(LevelString, OrderString, DestString). 

%% ====================================================================
%% Internal functions
%% ====================================================================

%%把一个字符串变成带顺序编号的tuple list 
get_reverse_char_tuple_list(String) ->
    FunGetCharTupleList =
        fun(Char, {CurNth, CurCharTupleList}) ->
                {CurNth + 1,
                 [{CurNth, Char}] ++ CurCharTupleList} 
        end,
    {_, TupleList} = lists:foldl(FunGetCharTupleList, {0, []}, String),
    TupleList.

%%获取层次遍历结果
get_level_traversal_string(MidString, PostString) ->
    PostReverseTupleList = get_reverse_char_tuple_list(PostString),
    RootChar = get_root_char(MidString, PostReverseTupleList), 
    get_level_traversal_string(part_string_by_root_char(MidString, RootChar), PostReverseTupleList, [RootChar]).

get_level_traversal_string(PartStringList, PostReverseTupleList, Result) ->
    Fun =
        fun(PartString, {CurIsAnyData, CurPartStringList, CurResult}) ->
                case PartString of
                    undefined ->
                        {CurIsAnyData, CurPartStringList, CurResult};
                    [] ->
                        {CurIsAnyData, CurPartStringList, CurResult};
                    _ ->
                        %%每次把每一层的数据取根节点，然后分割，直到所有的子树都没有数据为止
                        RootChar = get_root_char(PartString, PostReverseTupleList), 
                        [LeftString, RightString] = part_string_by_root_char(PartString, RootChar),
                        {true, CurPartStringList ++ [LeftString] ++ [RightString], CurResult ++ [RootChar]}
                end
        end,
    {IsAnyData, NewPartStringList, NewResult} = lists:foldl(Fun, {false, [], Result}, PartStringList),
    case IsAnyData of
        false ->
            Result;
        true ->
            get_level_traversal_string(NewPartStringList, PostReverseTupleList, NewResult)
    end.
    
%%获取一个子树的根节点
get_root_char(String, PostReverseTupleList) ->
    FunGetRootChar = 
        fun(Char, {CurMinNth, CurRootChar}) ->
                case CurMinNth of
                    0 ->
                        lists:keyfind(Char, 2, PostReverseTupleList);
                    _ ->
                        %%找当前的根节点，判断在后序遍历中位置序号最大的
                        {FindNth, _} = lists:keyfind(Char, 2, PostReverseTupleList),
                        case FindNth > CurMinNth of
                            true ->
                                {FindNth, Char};
                            false ->
                                {CurMinNth, CurRootChar}
                        end
                end
        end,
    {_, RootChar} = lists:foldl(FunGetRootChar, {0, 0}, String),
    RootChar.
    
%% string:tokens 直接返回的话判定不了左/右子树为空，需要额外判定
part_string_by_root_char(String, RootChar) ->
    case hd(String) of
        RootChar ->
            [undefined, tl(String)];
        _ ->
            ReverseString = lists:reverse(String),
            case hd(ReverseString) of
                RootChar ->
                    [lists:reverse(tl(ReverseString)), undefined];
                _ ->
                    string:tokens(String, [RootChar])
            end
    end.

%%此处遍历取每一个char在层次遍历中的位置
get_password_string(LevelString, OrderString, DestString) ->
    LevelTupleList = get_reverse_char_tuple_list(LevelString),
    
    FunGetDestTupleList = 
        fun(Nth) ->
                DestChar = lists:nth(Nth, DestString),
                OrderChar = lists:nth(Nth, OrderString),
                
                {OrderIndex, _} = lists:keyfind(OrderChar, 2, LevelTupleList),
                {OrderIndex, DestChar}
        end,
    DestTupleList = lists:map(FunGetDestTupleList, lists:seq(1, length(DestString))),
    {_, Result} = lists:unzip(lists:keysort(1, DestTupleList)),
    lists:flatten(Result).


%%递归得出顺序遍历结果 (用于验证写了个)
get_pre_string(String, PostReverseTupleList) ->
    get_pre_string(String, PostReverseTupleList, "").

get_pre_string(undefined, _PostReverseTupleList, ResultTree) ->
    ResultTree;
get_pre_string(String, _PostReverseTupleList, ResultTree) when length(String) =:= 1 ->
    ResultTree ++ String;
get_pre_string(String, PostReverseTupleList, ResultTree) ->
    %%先寻找子树根节点
    RootChar = get_root_char(String, PostReverseTupleList),
    [LeftTreeString, RightTreeString] = part_string_by_root_char(String, RootChar),
    %%再递归子树
    ResultTree ++ [RootChar] ++ 
        get_pre_string(LeftTreeString, PostReverseTupleList, "") ++
        get_pre_string(RightTreeString, PostReverseTupleList, "").
