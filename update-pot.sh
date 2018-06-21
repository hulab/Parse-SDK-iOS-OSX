#!/bin/sh

# Created by Maxime Epain on 06/02/2018.
# Copyright © 2018 Hulab. All rights reserved.
#
# The methods and techniques described herein are considered trade secrets
# and/or confidential. Reproduction or distribution, in whole or in part,
# is forbidden except by express written permission of Hulab.
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

die() {
    echo "ERROR: $*" >&2
    exit 1
}

usage() {
    echo "USAGE: $(basename $0) <src-dir>"
    exit 1
}

if [ "$#" -ne 1 ]; then
    usage
fi

src="$1"

if [ ! -d "$src" ] ; then
    die "'$src' is not a dir"
fi

keywords="-kPOLocalizedString \
-kPOLocalizedStringFromContext:2c,1 \
-kPOLocalizedPluralFormat:1,2 \
-kPOLocalizedPluralFormatFromContext:4c,1,2 \
-kPOLocalizedStringInBundle:2 \
-kPOLocalizedStringFromContextInBundle:3c,2 \
-kPOLocalizedPluralFormatInBundle:2,3 \
-kPOLocalizedPluralFormatFromContextInBundle:5c,2,3"

find $src \( -iname "*.m" -o -iname "*.swift" -o -iname "*.java" \) -print0 | xargs -0 /usr/local/opt/gettext/bin/xgettext --no-location --join-existing --omit-header --language=ObjectiveC --language=Java --from-code=UTF-8 $keywords -o po/en.po
