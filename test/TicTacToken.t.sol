// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.15;

import "../lib/ds-test/src/test.sol";
import "../lib/forge-std/src/Vm.sol";

import "../contracts/NFT.sol";
import "../contracts/Token.sol";
import "../contracts/TicTacToken.sol";

contract User {
    TicTacToken internal ttt;
    Vm internal vm;
    address internal userAddress;

    constructor(
        TicTacToken _ttt,
        Vm _vm,
        address _userAddress
    ) {
        ttt = _ttt;
        vm = _vm;
        userAddress = _userAddress;
    }

    function markSpace(uint256 id, uint256 space) public {
        vm.prank(userAddress);
        ttt.markSpace(id, space);
    }
}

contract TestTicTacToken is DSTest {
    uint256 constant EMPTY = 0;
    uint256 public constant X = 1;
    uint256 public constant O = 2;

    address public constant PLAYER_X = address(2);
    address public constant PLAYER_O = address(3);
    address public constant NON_PLAYER = address(4);

    User internal playerX;
    User internal playerO;
    User internal nonPlayer;

    Vm public constant vm = Vm(HEVM_ADDRESS);
    Token internal token;
    NFT internal nft;
    TicTacToken internal ttt;

    function setUp() public {
        token = new Token();
        nft = new NFT();
        ttt = new TicTacToken(address(token), address(nft));
        token.transferOwnership(address(ttt));
        nft.transferOwnership(address(ttt));

        playerX = new User(ttt, vm, PLAYER_X);
        playerO = new User(ttt, vm, PLAYER_O);
        nonPlayer = new User(ttt, vm, NON_PLAYER);
        ttt.newGame(PLAYER_X, PLAYER_O);
    }

    function test_get_full_board() public {
        uint256[9] memory board = ttt.getBoard(0);
        for (uint256 i; i < 9; i++) {
            assertEq(board[i], EMPTY);
        }
    }

    function test_marks_first_square_with_x() public {
        playerX.markSpace(1, 0);
        uint256[9] memory board = ttt.getBoard(1);
        assertEq(board[0], X);
    }

    function test_marks_first_square_with_o() public {
        playerO.markSpace(1, 0);
        uint256[9] memory board = ttt.getBoard(1);
        assertEq(board[0], O);
    }

    function test_cannot_overwrite_marked_square() public {
        playerX.markSpace(1, 2);

        vm.expectRevert("Already occupied");
        playerO.markSpace(1, 2);
    }

    function test_validates_marker_is_valid_index() public {
        vm.expectRevert("Invalid space");
        playerX.markSpace(1, 9);
    }

    function test_validates_alternating_turns_with_x() public {
        playerX.markSpace(1, 0);

        vm.expectRevert("Not your turn");
        playerX.markSpace(1, 1);
    }

    function test_validates_alternating_turns_with_o() public {
        playerO.markSpace(1, 0);

        vm.expectRevert("Not your turn");
        playerO.markSpace(1, 1);
    }

    function test_checks_diagonal_win() public {
        playerX.markSpace(1, 0);
        playerO.markSpace(1, 1);
        playerX.markSpace(1, 4);
        playerO.markSpace(1, 2);
        playerX.markSpace(1, 8);

        assertEq(ttt.winner(1), X);
    }

    function test_checks_antidiagonal_win() public {
        playerX.markSpace(1, 6);
        playerO.markSpace(1, 1);
        playerX.markSpace(1, 4);
        playerO.markSpace(1, 3);
        playerX.markSpace(1, 2);

        assertEq(ttt.winner(1), X);
    }

    function test_checks_column_win() public {
        playerO.markSpace(1, 0);
        playerX.markSpace(1, 1);
        playerO.markSpace(1, 3);
        playerX.markSpace(1, 2);
        playerO.markSpace(1, 6);

        assertEq(ttt.winner(1), O);
    }

    function test_checks_row_win() public {
        playerX.markSpace(1, 0);
        playerO.markSpace(1, 3);
        playerX.markSpace(1, 1);
        playerO.markSpace(1, 4);
        playerX.markSpace(1, 2);

        assertEq(ttt.winner(1), X);
    }

    function test_checks_row_win2() public {
        playerO.markSpace(1, 0);
        playerX.markSpace(1, 3);
        playerO.markSpace(1, 1);
        playerX.markSpace(1, 4);
        playerO.markSpace(1, 2);

        assertEq(ttt.winner(1), O);
    }

    function test_checks_row_win3() public {
        playerO.markSpace(1, 6);
        playerX.markSpace(1, 3);
        playerO.markSpace(1, 7);
        playerX.markSpace(1, 4);
        playerO.markSpace(1, 8);

        assertEq(ttt.winner(1), O);
    }

    function test_checks_tie() public {
        playerX.markSpace(1, 0);
        playerO.markSpace(1, 1);
        playerX.markSpace(1, 2);
        playerO.markSpace(1, 3);
        playerX.markSpace(1, 4);
        playerO.markSpace(1, 5);
        playerX.markSpace(1, 7);
        playerO.markSpace(1, 6);

        assertEq(ttt.winner(1), 0);
    }

    function test_auth_non_player_cannot_mark_board() public {
        vm.expectRevert("Unauthorized");
        nonPlayer.markSpace(1, 0);
    }

    function test_auth_playerX_can_mark_board() public {
        playerX.markSpace(1, 0);
    }

    function test_auth_playerO_can_mark_board() public {
        playerO.markSpace(1, 0);
    }

    function test_create_new_game() public {
        ttt.newGame(PLAYER_X, PLAYER_O);
        playerX.markSpace(2, 0);
        assertEq(ttt.getBoard(2)[0], X);

        ttt.newGame(PLAYER_X, PLAYER_O);
        playerX.markSpace(3, 0);
        assertEq(ttt.getBoard(3)[0], X);
    }

    function test_creating_game_issues_tokens_to_players() public {
        assertEq(nft.balanceOf(PLAYER_X), 1);
        assertEq(nft.ownerOf(1), PLAYER_X);

        assertEq(nft.balanceOf(PLAYER_O), 1);
        assertEq(nft.ownerOf(2), PLAYER_O);
    }

    function test_token_ids_are_function_of_game_ids() public {
        (uint256 xTokenId, uint256 oTokenId) = ttt.tokenIds(1);
        assertEq(xTokenId, 1);
        assertEq(oTokenId, 2);

        (xTokenId, oTokenId) = ttt.tokenIds(2);
        assertEq(xTokenId, 3);
        assertEq(oTokenId, 4);

        (xTokenId, oTokenId) = ttt.tokenIds(3);
        assertEq(xTokenId, 5);
        assertEq(oTokenId, 6);
    }

    function test_tracks_wins_by_address() public {
        assertEq(ttt.wins(PLAYER_X), 0);

        playerX.markSpace(1, 0);
        playerO.markSpace(1, 3);
        playerX.markSpace(1, 1);
        playerO.markSpace(1, 4);
        playerX.markSpace(1, 2);

        assertEq(ttt.wins(PLAYER_X), 1);

        ttt.newGame(PLAYER_X, PLAYER_O);
        playerO.markSpace(2, 6);
        playerX.markSpace(2, 3);
        playerO.markSpace(2, 7);
        playerX.markSpace(2, 4);
        playerO.markSpace(2, 8);

        assertEq(ttt.wins(PLAYER_O), 1);

        ttt.newGame(PLAYER_X, PLAYER_O);
        playerX.markSpace(3, 0);
        playerO.markSpace(3, 3);
        playerX.markSpace(3, 1);
        playerO.markSpace(3, 4);
        playerX.markSpace(3, 2);

        assertEq(ttt.wins(PLAYER_X), 2);
    }

    function test_tracks_points_by_address() public {
        assertEq(token.balanceOf(PLAYER_X), 0);

        playerX.markSpace(1, 0);
        playerO.markSpace(1, 3);
        playerX.markSpace(1, 1);
        playerO.markSpace(1, 4);
        playerX.markSpace(1, 2);

        assertEq(token.balanceOf(PLAYER_X), 5 ether);
    }

    function test_has_token() public {
        assertEq(address(ttt.token()), address(token));
    }

    function test_tracks_tokens_by_address() public {
        assertEq(token.balanceOf(PLAYER_X), 0);

        playerX.markSpace(1, 0);
        playerO.markSpace(1, 3);
        playerX.markSpace(1, 1);
        playerO.markSpace(1, 4);
        playerX.markSpace(1, 2);

        assertEq(token.balanceOf(PLAYER_X), 5 ether);
    }

    function test_tracks_games_by_address() public {
        ttt.newGame(PLAYER_X, PLAYER_O);
        ttt.newGame(PLAYER_X, PLAYER_O);

        uint256[3] memory expectedGameIds = [uint256(1), 2, 3];
        uint256[] memory games = ttt.gamesByPlayer(PLAYER_X);

        for (uint256 i; i < 3; i++) {
            assertEq(games[i], expectedGameIds[i]);
        }
    }
}
